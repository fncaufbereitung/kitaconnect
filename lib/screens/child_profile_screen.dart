import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/role_guard.dart';

const Color _ink = Color(0xFF334155);
const Color _mutedInk = Color(0xFF64748B);
const Color _lilac = Color(0xFFEDE7FF);
const Color _peach = Color(0xFFFFE8D6);
const Color _sky = Color(0xFFDDF1FF);
const Color _rose = Color(0xFFFFDCEB);
const Color _yellow = Color(0xFFFFF1A8);
const Color _purple = Color(0xFF7C3AED);
const Color _pink = Color(0xFFDB2777);
const Color _blue = Color(0xFF0284C7);
const Color _green = Color(0xFF059669);

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
      return _TopLevelChildProfile(
        authService: widget.authService,
        childId: widget.childId!,
      );
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
  final AuthService authService;
  final String childId;

  const _TopLevelChildProfile({
    required this.authService,
    required this.childId,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('ChildProfileScreen: loading child profile childId=$childId');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Kindprofil',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: _ink),
      ),
      body: _GradientScaffoldBody(
        child: StreamBuilder<DocumentSnapshot>(
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
            return FutureBuilder<UserAccess?>(
              future: RoleGuardService(authService: authService).loadAccess(),
              builder: (context, accessSnapshot) {
                if (accessSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final access = accessSnapshot.data;
                if (access == null || !access.canViewChild(childId, data)) {
                  return const AccessDeniedScreen();
                }

                final fullName = readString(data, 'fullName');
                final groupName = readString(data, 'groupName');
                final birthDate = formatBirthDate(data['birthDate']);
                final notes = readString(data, 'notes');
                final parentIds = readParentIds(data['parentIds']);
                final canSeeParentIds = access.isAdmin || access.isTeacher;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 92, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ChildHeroCard(
                        fullName: fullName,
                        groupName: groupName,
                        birthDate: birthDate,
                        parentCount: parentIds.length,
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ProfileChip(
                            icon: Icons.groups_rounded,
                            label: groupName.isEmpty
                                ? 'Keine Gruppe'
                                : groupName,
                            color: _green,
                          ),
                          _ProfileChip(
                            icon: Icons.cake_rounded,
                            label: birthDate.isEmpty
                                ? 'Geburtsdatum'
                                : birthDate,
                            color: _pink,
                          ),
                          _ProfileChip(
                            icon: Icons.family_restroom_rounded,
                            label: parentIds.isEmpty
                                ? 'Keine Zuordnung'
                                : '${parentIds.length} Elternkonto',
                            color: _purple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _ProfileInfoCard(
                        title: 'Stammdaten',
                        icon: Icons.badge_rounded,
                        color: _blue,
                        rows: [
                          _InfoRow(label: 'Name', value: fullName),
                          _InfoRow(label: 'Gruppe', value: groupName),
                          _InfoRow(label: 'Geburtsdatum', value: birthDate),
                          if (canSeeParentIds)
                            _InfoRow(
                              label: 'Eltern UIDs',
                              value: parentIds.isEmpty
                                  ? 'Keine Zuordnung'
                                  : parentIds.join(', '),
                            ),
                          _InfoRow(label: 'Notizen', value: notes),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Kindbezogene Bereiche',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Alles Wichtige rund um den Kita-Alltag.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _mutedInk,
                        ),
                      ),
                      const SizedBox(height: 14),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.98,
                        children: const [
                          _PlaceholderSection(
                            title: 'Nachrichten',
                            icon: Icons.chat_bubble_rounded,
                            colors: [Color(0xFFEAF7FF), _sky],
                            color: _blue,
                          ),
                          _PlaceholderSection(
                            title: 'Fotos',
                            icon: Icons.photo_rounded,
                            colors: [Color(0xFFFFF7E8), _peach],
                            color: Color(0xFFF97316),
                          ),
                          _PlaceholderSection(
                            title: 'Tagesbericht',
                            icon: Icons.assignment_rounded,
                            colors: [Color(0xFFFFF2F7), _rose],
                            color: _pink,
                          ),
                          _PlaceholderSection(
                            title: 'Entwicklung',
                            icon: Icons.auto_stories_rounded,
                            colors: [Color(0xFFF6EEFF), _lilac],
                            color: _purple,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Mein Kind',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: _ink),
      ),
      body: _GradientScaffoldBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 92, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ChildHeroCard(
                fullName: childNameController.text,
                groupName: groupController.text,
                birthDate: birthDateController.text,
                parentCount: 1,
              ),
              const SizedBox(height: 18),
              _ProfileInfoCard(
                title: 'Profil bearbeiten',
                icon: Icons.edit_note_rounded,
                color: _purple,
                children: [
                  _PremiumTextField(
                    controller: childNameController,
                    labelText: 'Name des Kindes',
                    icon: Icons.face_rounded,
                  ),
                  const SizedBox(height: 16),
                  _PremiumTextField(
                    controller: groupController,
                    labelText: 'Gruppe',
                    hintText: 'z.B. Sonnengruppe',
                    icon: Icons.groups_rounded,
                  ),
                  const SizedBox(height: 16),
                  _PremiumTextField(
                    controller: birthDateController,
                    labelText: 'Geburtsdatum',
                    hintText: 'z.B. 21.05.2021',
                    icon: Icons.cake_rounded,
                  ),
                  const SizedBox(height: 16),
                  _PremiumTextField(
                    controller: allergiesController,
                    labelText: 'Allergien / Hinweise',
                    icon: Icons.medical_information_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: loading ? null : onSave,
                      icon: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.4,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: const Text('Speichern'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _purple,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientScaffoldBody extends StatelessWidget {
  final Widget child;

  const _GradientScaffoldBody({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
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
      child: child,
    );
  }
}

class _ChildHeroCard extends StatelessWidget {
  final String fullName;
  final String groupName;
  final String birthDate;
  final int parentCount;

  const _ChildHeroCard({
    required this.fullName,
    required this.groupName,
    required this.birthDate,
    required this.parentCount,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = fullName.isEmpty ? 'Kindprofil' : fullName;

    return Container(
      width: double.infinity,
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
            color: const Color(0xFFA78BFA).withValues(alpha: 0.30),
            blurRadius: 28,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const _DecorativeIcon(
            icon: Icons.auto_awesome_rounded,
            color: Colors.white24,
            size: 104,
            right: -18,
            top: -24,
          ),
          const _DecorativeIcon(
            icon: Icons.favorite_rounded,
            color: Colors.white30,
            size: 28,
            right: 96,
            top: 6,
          ),
          const _DecorativeIcon(
            icon: Icons.star_rounded,
            color: Colors.white38,
            size: 22,
            left: 132,
            bottom: 8,
          ),
          Row(
            children: [
              _ChildAvatar(name: displayName),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeroMiniChip(
                          icon: Icons.groups_rounded,
                          label: groupName.isEmpty ? 'Gruppe' : groupName,
                        ),
                        _HeroMiniChip(
                          icon: Icons.family_restroom_rounded,
                          label: parentCount == 0
                              ? 'Keine Eltern'
                              : '$parentCount verbunden',
                        ),
                      ],
                    ),
                    if (birthDate.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _HeroMiniChip(icon: Icons.cake_rounded, label: birthDate),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChildAvatar extends StatelessWidget {
  final String name;

  const _ChildAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.26),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 66,
          height: 66,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_yellow, _peach]),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                color: _pink,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroMiniChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroMiniChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_InfoRow>? rows;
  final List<Widget>? children;

  const _ProfileInfoCard({
    required this.title,
    required this.icon,
    required this.color,
    this.rows,
    this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.90)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF94A3B8).withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
              ),
              Icon(
                Icons.auto_awesome_rounded,
                color: color.withValues(alpha: 0.32),
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (rows != null)
            for (final row in rows!) row,
          if (children != null) ...children!,
        ],
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ProfileChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: _mutedInk,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData icon;
  final int maxLines;

  const _PremiumTextField({
    required this.controller,
    required this.labelText,
    required this.icon,
    this.hintText,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon, color: _purple),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: _purple, width: 1.4),
        ),
      ),
    );
  }
}

class _PlaceholderSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> colors;
  final Color color;

  const _PlaceholderSection({
    required this.title,
    required this.icon,
    required this.colors,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            top: -18,
            child: Icon(
              Icons.favorite_rounded,
              color: Colors.white.withValues(alpha: 0.34),
              size: 66,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.82),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Vorbereitet',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _mutedInk,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DecorativeIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;

  const _DecorativeIcon({
    required this.icon,
    required this.color,
    required this.size,
    this.left,
    this.top,
    this.right,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final child = Icon(icon, color: color, size: size);

    if (left == null && top == null && right == null && bottom == null) {
      return child;
    }

    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: child,
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
