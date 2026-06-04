import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/role_guard.dart';

const Color _ink = Color(0xFF334155);
const Color _mutedInk = Color(0xFF64748B);
const Color _purple = Color(0xFF7C3AED);
const Color _pink = Color(0xFFDB2777);
const Color _blue = Color(0xFF0284C7);
const Color _yellow = Color(0xFFEAB308);

class ParentRequestsScreen extends StatefulWidget {
  final AuthService authService;

  const ParentRequestsScreen({super.key, required this.authService});

  @override
  State<ParentRequestsScreen> createState() => _ParentRequestsScreenState();
}

class _ParentRequestsScreenState extends State<ParentRequestsScreen> {
  late final RoleGuardService roleGuardService;
  late Future<_ParentRequestData> dataFuture;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    roleGuardService = RoleGuardService(authService: widget.authService);
    dataFuture = loadData();
  }

  Future<_ParentRequestData> loadData() async {
    final access = await roleGuardService.loadAccess();
    if (access == null || !access.isParent) {
      return _ParentRequestData(access: access, children: const []);
    }

    final childrenSnapshot = await FirebaseFirestore.instance
        .collection('children')
        .where('parentIds', arrayContains: access.uid)
        .get();
    final requestsSnapshot = await FirebaseFirestore.instance
        .collection('parentRequests')
        .where('parentId', isEqualTo: access.uid)
        .get();
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(access.uid)
        .get();

    final requests = requestsSnapshot.docs.toList()
      ..sort((a, b) {
        return _createdAtMillis(b.data()).compareTo(_createdAtMillis(a.data()));
      });

    return _ParentRequestData(
      access: access,
      parentName: _readString(userDoc.data() ?? const {}, 'name'),
      children: childrenSnapshot.docs.map(_RequestChild.fromDoc).toList(),
      requests: requests,
    );
  }

  Future<void> openComposer(
    _RequestAction action,
    _ParentRequestData data,
  ) async {
    if (data.children.isEmpty) return;

    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ParentRequestComposer(
          action: action,
          children: data.children,
          sending: sending,
          onSend: (child, extraNote, pickupTime) async {
            await sendRequest(data, action, child, extraNote, pickupTime);
          },
        );
      },
    );

    if (sent == true && mounted) {
      setState(() => dataFuture = loadData());
    }
  }

  Future<void> sendRequest(
    _ParentRequestData data,
    _RequestAction action,
    _RequestChild child,
    String extraNote,
    String pickupTime,
  ) async {
    final access = data.access;
    if (access == null || !access.isParent) return;
    if (!access.canViewChild(child.id, child.rawData)) {
      throw StateError('Keine Berechtigung fuer dieses Kind.');
    }

    setState(() => sending = true);

    try {
      await FirebaseFirestore.instance.collection('parentRequests').add({
        'parentId': access.uid,
        'parentName': data.parentName.isEmpty ? 'Elternteil' : data.parentName,
        'childId': child.id,
        'childName': child.name,
        'groupId': child.groupId,
        'groupName': child.groupName,
        'type': action.type,
        'title': action.title,
        'message': action.message,
        'extraNote': extraNote,
        'pickupTime': pickupTime,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      authService: widget.authService,
      allowed: (access) => access.isParent,
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
                  Color(0xFFFFEEF8),
                  Color(0xFFEFF7FF),
                  Color(0xFFEFFFF6),
                ],
              ),
            ),
            child: FutureBuilder<_ParentRequestData>(
              future: dataFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint(
                    'ParentRequestsScreen: load failed: ${snapshot.error}',
                  );
                  return const _StateMessage(
                    icon: Icons.error_outline_rounded,
                    title: 'Mitteilungen konnten nicht geladen werden',
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data;
                if (data == null || data.children.isEmpty) {
                  return const _StateMessage(
                    icon: Icons.child_care_rounded,
                    title: 'Kein Kind zugeordnet',
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(18, 96, 18, 28),
                  children: [
                    _HeroCard(childCount: data.children.length),
                    const SizedBox(height: 18),
                    for (final action in _requestActions) ...[
                      _ActionCard(
                        action: action,
                        onTap: () => openComposer(action, data),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'Gesendet',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (data.requests.isEmpty)
                      const _StateMessage(
                        icon: Icons.mark_email_read_rounded,
                        title: 'Keine Mitteilungen vorhanden',
                        compact: true,
                      )
                    else
                      for (final request in data.requests)
                        _RequestHistoryCard(request: request),
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

class _ParentRequestComposer extends StatefulWidget {
  final _RequestAction action;
  final List<_RequestChild> children;
  final bool sending;
  final Future<void> Function(
    _RequestChild child,
    String extraNote,
    String pickupTime,
  )
  onSend;

  const _ParentRequestComposer({
    required this.action,
    required this.children,
    required this.sending,
    required this.onSend,
  });

  @override
  State<_ParentRequestComposer> createState() => _ParentRequestComposerState();
}

class _ParentRequestComposerState extends State<_ParentRequestComposer> {
  final extraNoteController = TextEditingController();
  final pickupTimeController = TextEditingController();
  late _RequestChild selectedChild;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    selectedChild = widget.children.first;
  }

  @override
  void dispose() {
    extraNoteController.dispose();
    pickupTimeController.dispose();
    super.dispose();
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;
    pickupTimeController.text = time.format(context);
  }

  Future<void> send() async {
    if (sending) return;
    setState(() => sending = true);

    try {
      await widget.onSend(
        selectedChild,
        extraNoteController.text.trim(),
        pickupTimeController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gesendet')));
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler: $error')));
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEarlyPickup = widget.action.type == 'early_pickup';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.action.title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.action.message,
                style: const TextStyle(
                  color: _mutedInk,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              if (widget.children.length > 1)
                DropdownButtonFormField<_RequestChild>(
                  initialValue: selectedChild,
                  decoration: const InputDecoration(
                    labelText: 'Kind',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final child in widget.children)
                      DropdownMenuItem(value: child, child: Text(child.name)),
                  ],
                  onChanged: sending
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => selectedChild = value);
                        },
                )
              else
                _SelectedChildTile(child: selectedChild),
              const SizedBox(height: 14),
              if (isEarlyPickup) ...[
                TextField(
                  controller: pickupTimeController,
                  decoration: InputDecoration(
                    labelText: 'Abholzeit',
                    hintText: 'z.B. 13:30',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: sending ? null : pickTime,
                      icon: const Icon(Icons.schedule_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              TextField(
                controller: extraNoteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Optionale Notiz',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: sending ? null : send,
                  icon: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: const Text('Mitteilung senden'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final int childCount;

  const _HeroCard({required this.childCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8FB3), Color(0xFFA78BFA), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA78BFA).withValues(alpha: 0.28),
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
                  childCount == 1
                      ? 'Schnell eine Nachricht fuer dein Kind senden.'
                      : 'Kind auswaehlen und Nachricht senden.',
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

class _ActionCard extends StatelessWidget {
  final _RequestAction action;
  final VoidCallback onTap;

  const _ActionCard({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: action.colors),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: action.color.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.82),
                  shape: BoxShape.circle,
                ),
                child: Icon(action.icon, color: action.color, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _mutedInk,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: action.color),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestHistoryCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> request;

  const _RequestHistoryCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final data = request.data();
    final status = _readString(data, 'status');
    final pickupTime = _readString(data, 'pickupTime');
    final extraNote = _readString(data, 'extraNote');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEDE7FF),
          child: Icon(Icons.mark_email_read_rounded, color: _purple),
        ),
        title: Text(
          _readString(data, 'title'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          [
            _readString(data, 'childName'),
            if (pickupTime.isNotEmpty) 'Abholzeit: $pickupTime',
            if (extraNote.isNotEmpty) extraNote,
            if (status.isNotEmpty) 'Status: $status',
          ].where((item) => item.isNotEmpty).join('\n'),
        ),
      ),
    );
  }
}

class _SelectedChildTile extends StatelessWidget {
  final _RequestChild child;

  const _SelectedChildTile({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.child_care_rounded, color: _purple),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              child.groupName.isEmpty
                  ? child.name
                  : '${child.name} - ${child.groupName}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool compact;

  const _StateMessage({
    required this.icon,
    required this.title,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(compact ? 0 : 22),
        padding: EdgeInsets.all(compact ? 18 : 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _purple, size: compact ? 32 : 44),
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

class _ParentRequestData {
  final UserAccess? access;
  final String parentName;
  final List<_RequestChild> children;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> requests;

  const _ParentRequestData({
    required this.access,
    this.parentName = '',
    required this.children,
    this.requests = const [],
  });
}

class _RequestChild {
  final String id;
  final String name;
  final String groupId;
  final String groupName;
  final Map<String, dynamic> rawData;

  const _RequestChild({
    required this.id,
    required this.name,
    required this.groupId,
    required this.groupName,
    required this.rawData,
  });

  factory _RequestChild.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final fullName = _readString(data, 'fullName');
    final childName = _readString(data, 'childName');
    final groupIds = UserAccess.readStringList(data['groupIds']);
    return _RequestChild(
      id: doc.id,
      name: fullName.isEmpty
          ? childName.isEmpty
                ? 'Kind'
                : childName
          : fullName,
      groupId: _readString(data, 'groupId').isEmpty && groupIds.isNotEmpty
          ? groupIds.first
          : _readString(data, 'groupId'),
      groupName: _readString(data, 'groupName').isEmpty
          ? _readString(data, 'group')
          : _readString(data, 'groupName'),
      rawData: data,
    );
  }
}

class _RequestAction {
  final String type;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final List<Color> colors;

  const _RequestAction({
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.colors,
  });
}

const _requestActions = [
  _RequestAction(
    type: 'sick',
    title: 'Kind ist krank',
    message: 'Mein Kind ist krank und kommt heute nicht in die Kita.',
    icon: Icons.sick_rounded,
    color: _pink,
    colors: [Color(0xFFFFF2F7), Color(0xFFFFDCEB)],
  ),
  _RequestAction(
    type: 'early_pickup',
    title: 'Früher abholen',
    message: 'Mein Kind wird heute früher abgeholt.',
    icon: Icons.schedule_rounded,
    color: _blue,
    colors: [Color(0xFFEAF7FF), Color(0xFFDDF1FF)],
  ),
  _RequestAction(
    type: 'clothing_note',
    title: 'Mütze / Kappe',
    message: 'Mein Kind soll draußen bitte nur mit Mütze oder Kappe rausgehen.',
    icon: Icons.wb_sunny_rounded,
    color: _yellow,
    colors: [Color(0xFFFFFCEB), Color(0xFFFFF1A8)],
  ),
];

String _readString(Map<String, dynamic> data, String key) {
  final value = data[key];
  return value == null ? '' : value.toString();
}

int _createdAtMillis(Map<String, dynamic> data) {
  final createdAt = data['createdAt'];
  if (createdAt is Timestamp) return createdAt.millisecondsSinceEpoch;
  return 0;
}
