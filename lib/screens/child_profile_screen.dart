import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class ChildProfileScreen extends StatefulWidget {
  final AuthService authService;
  final String? childId;

  const ChildProfileScreen({
    super.key,
    required this.authService,
    this.childId,
  });

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  final childNameController = TextEditingController();
  final groupController = TextEditingController();
  final birthDateController = TextEditingController();
  final allergiesController = TextEditingController();
  bool loading = false;

  bool get usesTopLevelChildProfile => widget.childId != null;

  Future<void> saveChild() async {
    setState(() => loading = true);
    final uid = widget.authService.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('children')
        .doc('main_child')
        .set({
          'childName': childNameController.text.trim(),
          'group': groupController.text.trim(),
          'birthDate': birthDateController.text.trim(),
          'allergies': allergiesController.text.trim(),
          'updatedAt': Timestamp.now(),
        });

    if (mounted) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kind gespeichert')));
    }
  }

  Future<void> loadChild() async {
    if (usesTopLevelChildProfile) return;

    final uid = widget.authService.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('children')
        .doc('main_child')
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      childNameController.text = data['childName'] ?? '';
      groupController.text = data['group'] ?? '';
      birthDateController.text = data['birthDate'] ?? '';
      allergiesController.text = data['allergies'] ?? '';
      if (mounted) setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    loadChild();
  }

  @override
  void dispose() {
    childNameController.dispose();
    groupController.dispose();
    birthDateController.dispose();
    allergiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (usesTopLevelChildProfile) {
      return _TopLevelChildProfile(childId: widget.childId!);
    }

    return _LegacyEditableChildProfile(
      childNameController: childNameController,
      groupController: groupController,
      birthDateController: birthDateController,
      allergiesController: allergiesController,
      loading: loading,
      onSave: saveChild,
    );
  }
}

class _TopLevelChildProfile extends StatelessWidget {
  final String childId;

  const _TopLevelChildProfile({required this.childId});

  @override
  Widget build(BuildContext context) {
    debugPrint('ChildProfileScreen: loading child profile childId=$childId');

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      appBar: AppBar(title: const Text('Kindprofil')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('children')
            .doc(childId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Fehler beim Laden des Kindes'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.data!.exists) {
            return const Center(child: Text('Kind wurde nicht gefunden.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final fullName = readString(data, 'fullName');
          final groupName = readString(data, 'groupName');
          final birthDate = formatBirthDate(data['birthDate']);
          final notes = readString(data, 'notes');
          final parentIds = readParentIds(data['parentIds']);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileHero(
                  fullName: fullName,
                  groupName: groupName,
                  birthDate: birthDate,
                ),
                const SizedBox(height: 18),
                _InfoCard(
                  title: 'Stammdaten',
                  rows: [
                    _InfoRow(label: 'Name', value: fullName),
                    _InfoRow(label: 'Gruppe', value: groupName),
                    _InfoRow(label: 'Geburtsdatum', value: birthDate),
                    _InfoRow(
                      label: 'Eltern UIDs',
                      value: parentIds.isEmpty
                          ? 'Keine Zuordnung'
                          : parentIds.join(', '),
                    ),
                    _InfoRow(label: 'Notizen', value: notes),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Kindbezogene Bereiche',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.12,
                  children: const [
                    _PlaceholderSection(
                      title: 'Nachrichten',
                      icon: Icons.chat_bubble_rounded,
                      color: Colors.blue,
                    ),
                    _PlaceholderSection(
                      title: 'Fotos',
                      icon: Icons.photo_rounded,
                      color: Colors.orange,
                    ),
                    _PlaceholderSection(
                      title: 'Tagesbericht',
                      icon: Icons.assignment_rounded,
                      color: Colors.pink,
                    ),
                    _PlaceholderSection(
                      title: 'Entwicklung',
                      icon: Icons.auto_stories_rounded,
                      color: Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LegacyEditableChildProfile extends StatelessWidget {
  final TextEditingController childNameController;
  final TextEditingController groupController;
  final TextEditingController birthDateController;
  final TextEditingController allergiesController;
  final bool loading;
  final VoidCallback onSave;

  const _LegacyEditableChildProfile({
    required this.childNameController,
    required this.groupController,
    required this.birthDateController,
    required this.allergiesController,
    required this.loading,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mein Kind')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(26),
        child: Column(
          children: [
            const Icon(Icons.child_care, size: 90, color: Color(0xFF2563EB)),
            const SizedBox(height: 24),
            TextField(
              controller: childNameController,
              decoration: const InputDecoration(
                labelText: 'Name des Kindes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: groupController,
              decoration: const InputDecoration(
                labelText: 'Gruppe',
                hintText: 'z.B. Sonnengruppe',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: birthDateController,
              decoration: const InputDecoration(
                labelText: 'Geburtsdatum',
                hintText: 'z.B. 21.05.2021',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: allergiesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Allergien / Hinweise',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: loading ? null : onSave,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Speichern'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final String fullName;
  final String groupName;
  final String birthDate;

  const _ProfileHero({
    required this.fullName,
    required this.groupName,
    required this.birthDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF8B5CF6), Color(0xFFF472B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.child_care_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isEmpty ? 'Kindprofil' : fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    if (groupName.isNotEmpty) groupName,
                    if (birthDate.isNotEmpty) birthDate,
                  ].join(' · '),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoRow> rows;

  const _InfoCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            for (final row in rows) row,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(color: Color(0xFF1E293B), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _PlaceholderSection({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Vorbereitet',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

String readString(Map<String, dynamic> data, String key) {
  final value = data[key];
  return value == null ? '' : value.toString();
}

List<String> readParentIds(dynamic value) {
  if (value is Iterable) {
    return value.map((item) => item.toString()).toList();
  }

  return const [];
}

String formatBirthDate(dynamic value) {
  if (value is Timestamp) {
    final date = value.toDate();
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  if (value == null) return '';
  return value.toString();
}
