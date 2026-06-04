import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/role_guard.dart';

class EventsScreen extends StatefulWidget {
  final AuthService authService;

  const EventsScreen({super.key, required this.authService});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final titleController = TextEditingController();
  final dateController = TextEditingController();
  late final RoleGuardService roleGuardService;
  late final Future<UserAccess?> accessFuture;

  @override
  void initState() {
    super.initState();
    roleGuardService = RoleGuardService(authService: widget.authService);
    accessFuture = roleGuardService.loadAccess();
  }

  Future<void> addEvent(UserAccess access) async {
    if (!access.canEditContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine Berechtigung fuer Termine.')),
      );
      return;
    }

    if (titleController.text.trim().isEmpty ||
        dateController.text.trim().isEmpty) {
      return;
    }

    await FirebaseFirestore.instance.collection('events').add({
      'title': titleController.text.trim(),
      'date': dateController.text.trim(),
      ...access.contentScopeFields(),
      'createdAt': Timestamp.now(),
    });

    titleController.clear();
    dateController.clear();

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Termin erstellt')));
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserAccess?>(
      future: accessFuture,
      builder: (context, accessSnapshot) {
        if (accessSnapshot.hasError) {
          final error = accessSnapshot.error;
          if (error is FirebaseException) {
            debugPrint(
              'EventsScreen: access loading failed FirebaseException '
              'code=${error.code}, message=${error.message}',
            );
          } else {
            debugPrint('EventsScreen: access loading failed: $error');
          }
          return const _EventsScaffold(
            child: _EventsEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Termine konnten nicht geladen werden',
            ),
          );
        }

        if (accessSnapshot.connectionState == ConnectionState.waiting) {
          return const _EventsScaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final access = accessSnapshot.data;
        if (access == null) {
          debugPrint('EventsScreen: no access data available');
          return const AccessDeniedScreen();
        }

        final missingParentScope =
            access.isParent &&
            access.childIds.isEmpty &&
            access.groupIds.isEmpty &&
            access.groupNames.isEmpty;
        final canEdit = access.canEditContent;

        debugPrint(
          'EventsScreen: scope loaded uid=${access.uid}, role=${access.role}, '
          'childIds=${access.childIds}, groupIds=${access.groupIds}, '
          'groupNames=${access.groupNames}, '
          'missingParentScope=$missingParentScope',
        );

        return Scaffold(
          appBar: AppBar(title: const Text('Termine')),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (canEdit) ...[
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titel',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      labelText: 'Datum',
                      hintText: 'z.B. 25.06.2026',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => addEvent(access),
                      child: const Text('Termin speichern'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Expanded(
                  child: missingParentScope
                      ? const _EventsEmptyState(
                          icon: Icons.child_care_rounded,
                          title: 'Kein Kind zugeordnet',
                        )
                      : FutureBuilder<
                          List<QueryDocumentSnapshot<Map<String, dynamic>>>
                        >(
                          future: loadEvents(access),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              logFirestoreError(
                                'event load failed',
                                snapshot.error,
                                access,
                              );
                              return const _EventsEmptyState(
                                icon: Icons.error_outline_rounded,
                                title: 'Termine konnten nicht geladen werden',
                              );
                            }

                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                !snapshot.hasData) {
                              debugPrint(
                                'EventsScreen: event load waiting '
                                'uid=${access.uid}, role=${access.role}, '
                                'scope=${describeQueryScope(access)}',
                              );
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final events = snapshot.data ?? const [];
                            debugPrint(
                              'EventsScreen: event load delivered '
                              '${events.length} docs uid=${access.uid}, '
                              'role=${access.role}, '
                              'state=${snapshot.connectionState}',
                            );

                            if (events.isEmpty) {
                              return const _EventsEmptyState(
                                icon: Icons.event_busy_rounded,
                                title: 'Keine Termine vorhanden',
                              );
                            }

                            return ListView.builder(
                              itemCount: events.length,
                              itemBuilder: (context, index) {
                                final data = events[index].data();
                                return Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.calendar_month),
                                    title: Text(data['title'] ?? ''),
                                    subtitle: Text(data['date'] ?? ''),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> loadEvents(
    UserAccess access,
  ) async {
    final collection = FirebaseFirestore.instance.collection('events');

    if (access.isAdmin) {
      debugPrint('EventsScreen: loading admin events with createdAt order');
      final snapshot = await collection
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs;
    }

    final queries = <Future<QuerySnapshot<Map<String, dynamic>>>>[];

    if (access.groupIds.isNotEmpty) {
      final ids = access.groupIds.take(30).toList();
      debugPrint('EventsScreen: adding groupIds event query groupIds=$ids');
      queries.add(collection.where('groupIds', arrayContainsAny: ids).get());
    }

    if (access.childIds.isNotEmpty) {
      final ids = access.childIds.take(30).toList();
      debugPrint('EventsScreen: adding childIds event query childIds=$ids');
      queries.add(collection.where('childIds', arrayContainsAny: ids).get());
    }

    if (access.groupNames.isNotEmpty) {
      final names = access.groupNames.take(30).toList();
      debugPrint('EventsScreen: adding legacy group queries names=$names');
      queries.add(collection.where('groupName', whereIn: names).get());
      queries.add(collection.where('group', whereIn: names).get());
    }

    if (access.isTeacher) {
      debugPrint(
        'EventsScreen: adding teacher createdBy fallback query '
        'uid=${access.uid}',
      );
      queries.add(collection.where('createdBy', isEqualTo: access.uid).get());
    }

    if (access.isParent) {
      debugPrint(
        'EventsScreen: adding parentIds fallback event query uid=${access.uid}',
      );
      queries.add(
        collection.where('parentIds', arrayContains: access.uid).get(),
      );
    }

    if (queries.isEmpty) {
      debugPrint(
        'EventsScreen: no event queries built uid=${access.uid}, '
        'role=${access.role}',
      );
      return const [];
    }

    try {
      final snapshots = await Future.wait(queries);
      final docsById = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

      for (final snapshot in snapshots) {
        for (final doc in snapshot.docs) {
          docsById[doc.id] = doc;
        }
      }

      final docs = docsById.values.toList()
        ..sort((a, b) {
          return readCreatedAtMillis(
            b.data(),
          ).compareTo(readCreatedAtMillis(a.data()));
        });

      return docs;
    } catch (error) {
      logFirestoreError('event scoped query failed', error, access);
      rethrow;
    }
  }

  String describeQueryScope(UserAccess access) {
    if (access.isAdmin) return 'all-events';
    if (access.groupIds.isNotEmpty) return 'groupIds=${access.groupIds}';
    if (access.childIds.isNotEmpty) return 'childIds=${access.childIds}';
    if (access.groupNames.isNotEmpty) return 'groupNames=${access.groupNames}';
    if (access.isTeacher) return 'createdBy=${access.uid}';
    return 'missing-parent-scope';
  }

  int readCreatedAtMillis(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) return createdAt.millisecondsSinceEpoch;
    return 0;
  }

  void logFirestoreError(String label, Object? error, UserAccess access) {
    if (error is FirebaseException) {
      debugPrint(
        'EventsScreen: $label FirebaseException '
        'code=${error.code}, message=${error.message}, '
        'uid=${access.uid}, role=${access.role}, '
        'childIds=${access.childIds}, groupIds=${access.groupIds}, '
        'groupNames=${access.groupNames}',
      );
      return;
    }

    debugPrint(
      'EventsScreen: $label error=$error, uid=${access.uid}, '
      'role=${access.role}, childIds=${access.childIds}, '
      'groupIds=${access.groupIds}, groupNames=${access.groupNames}',
    );
  }
}

class _EventsScaffold extends StatelessWidget {
  final Widget? body;
  final Widget? child;

  const _EventsScaffold({this.body, this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Termine')),
      body: body ?? Center(child: child),
    );
  }
}

class _EventsEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;

  const _EventsEmptyState({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1A8).withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: const Color(0xFFEAB308), size: 38),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
