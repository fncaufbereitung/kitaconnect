import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/role_guard.dart';

const Color _ink = Color(0xFF334155);
const Color _mutedInk = Color(0xFF64748B);
const Color _purple = Color(0xFF7C3AED);
const Color _green = Color(0xFF059669);
const Color _blue = Color(0xFF0284C7);
const Color _pink = Color(0xFFDB2777);

class TeacherRequestsScreen extends StatefulWidget {
  final AuthService authService;

  const TeacherRequestsScreen({super.key, required this.authService});

  @override
  State<TeacherRequestsScreen> createState() => _TeacherRequestsScreenState();
}

class _TeacherRequestsScreenState extends State<TeacherRequestsScreen> {
  late final RoleGuardService roleGuardService;
  late Future<_TeacherRequestData> dataFuture;
  String? updatingId;

  @override
  void initState() {
    super.initState();
    roleGuardService = RoleGuardService(authService: widget.authService);
    dataFuture = loadData();
  }

  Future<_TeacherRequestData> loadData() async {
    final access = await roleGuardService.loadAccess();
    if (access == null || (!access.isTeacher && !access.isAdmin)) {
      return _TeacherRequestData(access: access);
    }

    final requests = access.isAdmin
        ? await loadAdminRequests()
        : await loadTeacherRequests(access);

    requests.sort((a, b) {
      return _createdAtMillis(b.data()).compareTo(_createdAtMillis(a.data()));
    });

    return _TeacherRequestData(access: access, requests: requests);
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  loadAdminRequests() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('parentRequests')
        .get();
    return snapshot.docs;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> loadTeacherRequests(
    UserAccess access,
  ) async {
    final collection = FirebaseFirestore.instance.collection('parentRequests');
    final queries = <Future<QuerySnapshot<Map<String, dynamic>>>>[];

    if (access.groupIds.isNotEmpty) {
      queries.add(
        collection
            .where('groupId', whereIn: access.groupIds.take(30).toList())
            .get(),
      );
    }

    if (access.groupNames.isNotEmpty) {
      queries.add(
        collection
            .where('groupName', whereIn: access.groupNames.take(30).toList())
            .get(),
      );
    }

    if (access.childIds.isNotEmpty) {
      queries.add(
        collection
            .where('childId', whereIn: access.childIds.take(30).toList())
            .get(),
      );
    }

    if (queries.isEmpty) return const [];

    final snapshots = await Future.wait(queries);
    final docsById = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

    for (final snapshot in snapshots) {
      for (final doc in snapshot.docs) {
        docsById[doc.id] = doc;
      }
    }

    return docsById.values.toList();
  }

  Future<void> updateStatus(String requestId, String status) async {
    setState(() => updatingId = requestId);

    try {
      await FirebaseFirestore.instance
          .collection('parentRequests')
          .doc(requestId)
          .update({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gespeichert')));
      setState(() => dataFuture = loadData());
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler: $error')));
      }
    } finally {
      if (mounted) setState(() => updatingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      authService: widget.authService,
      allowed: (access) => access.isAdmin || access.isTeacher,
      builder: (context, access) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text(
              'Elternmitteilungen',
              style: TextStyle(color: _ink, fontWeight: FontWeight.w900),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: _ink),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF7EA),
                  Color(0xFFEFFFF6),
                  Color(0xFFEFF7FF),
                  Color(0xFFFFEEF8),
                ],
              ),
            ),
            child: FutureBuilder<_TeacherRequestData>(
              future: dataFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint(
                    'TeacherRequestsScreen: load failed: ${snapshot.error}',
                  );
                  return const _StateMessage(
                    icon: Icons.error_outline_rounded,
                    title: 'Mitteilungen konnten nicht geladen werden',
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final requests = snapshot.data?.requests ?? const [];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(18, 96, 18, 28),
                  children: [
                    _HeroCard(isAdmin: access.isAdmin),
                    const SizedBox(height: 18),
                    if (requests.isEmpty)
                      const _StateMessage(
                        icon: Icons.mark_email_read_rounded,
                        title: 'Keine Mitteilungen vorhanden',
                      )
                    else
                      for (final request in requests)
                        _TeacherRequestCard(
                          request: request,
                          updating: updatingId == request.id,
                          onRead: () => updateStatus(request.id, 'read'),
                          onDone: () => updateStatus(request.id, 'done'),
                        ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  final bool isAdmin;

  const _HeroCard({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          colors: [Color(0xFF34D399), Color(0xFF38BDF8), Color(0xFFA78BFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.24),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_unread_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Elternmitteilungen',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAdmin
                      ? 'Alle offenen Hinweise der Eltern im Blick.'
                      : 'Hinweise fuer deine Gruppen schnell bearbeiten.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherRequestCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> request;
  final bool updating;
  final VoidCallback onRead;
  final VoidCallback onDone;

  const _TeacherRequestCard({
    required this.request,
    required this.updating,
    required this.onRead,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final data = request.data();
    final status = _readString(data, 'status');
    final extraNote = _readString(data, 'extraNote');
    final pickupTime = _readString(data, 'pickupTime');
    final groupName = _readString(data, 'groupName');

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _statusColor(status).withValues(alpha: 0.12),
                  child: Icon(Icons.mail_rounded, color: _statusColor(status)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _readString(data, 'title'),
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          _readString(data, 'childName'),
                          if (groupName.isNotEmpty) groupName,
                          _readString(data, 'parentName'),
                        ].where((item) => item.isNotEmpty).join(' - '),
                        style: const TextStyle(
                          color: _mutedInk,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _readString(data, 'message'),
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
            ),
            if (pickupTime.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Abholzeit: $pickupTime',
                style: const TextStyle(
                  color: _blue,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
            if (extraNote.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(extraNote, style: const TextStyle(color: _mutedInk)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: updating || status == 'read' ? null : onRead,
                    icon: const Icon(Icons.visibility_rounded),
                    label: const Text('Gelesen'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: updating || status == 'done' ? null : onDone,
                    icon: updating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded),
                    label: const Text('Erledigt'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'done' => _green,
      'read' => _blue,
      _ => _pink,
    };
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'done' => 'done',
      'read' => 'read',
      _ => 'open',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _purple.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _purple,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;

  const _StateMessage({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(22),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _purple, size: 44),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherRequestData {
  final UserAccess? access;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> requests;

  const _TeacherRequestData({required this.access, this.requests = const []});
}

String _readString(Map<String, dynamic> data, String key) {
  final value = data[key];
  return value == null ? '' : value.toString();
}

int _createdAtMillis(Map<String, dynamic> data) {
  final createdAt = data['createdAt'];
  if (createdAt is Timestamp) return createdAt.millisecondsSinceEpoch;
  return 0;
}
