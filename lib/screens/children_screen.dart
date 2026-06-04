import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/role_guard.dart';
import 'child_profile_screen.dart';
import 'dashboard_screen.dart' show createPremiumRoute;

class ChildrenScreen extends StatefulWidget {
  final AuthService authService;

  const ChildrenScreen({super.key, required this.authService});

  @override
  State<ChildrenScreen> createState() => _ChildrenScreenState();
}

class _ChildrenScreenState extends State<ChildrenScreen> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final birthDateController = TextEditingController();
  final groupNameController = TextEditingController();
  final parentUidController = TextEditingController();
  final notesController = TextEditingController();
  bool saving = false;
  late final RoleGuardService roleGuardService;

  @override
  void initState() {
    super.initState();
    roleGuardService = RoleGuardService(authService: widget.authService);
  }

  Future<void> addChild(UserAccess access) async {
    if (!access.canManageChildren) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine Berechtigung fuer Kinderanlage.')),
      );
      return;
    }

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final birthDate = birthDateController.text.trim();
    final groupName = groupNameController.text.trim();
    final parentUid = parentUidController.text.trim();
    final notes = notesController.text.trim();
    final currentUser = widget.authService.currentUser;

    if (firstName.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Vorname und Nachname eingeben.')),
      );
      return;
    }

    if (currentUser == null) return;

    setState(() => saving = true);

    try {
      final parentIds = parentUid.isEmpty ? <String>[] : <String>[parentUid];
      final fullName = '$firstName $lastName';

      await FirebaseFirestore.instance.collection('children').add({
        'firstName': firstName,
        'lastName': lastName,
        'fullName': fullName,
        'birthDate': birthDate,
        'groupName': groupName,
        'parentIds': parentIds,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': currentUser.uid,
      });

      firstNameController.clear();
      lastNameController.clear();
      birthDateController.clear();
      groupNameController.clear();
      parentUidController.clear();
      notesController.clear();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kind hinzugefuegt')));
      }
    } catch (error, stackTrace) {
      debugPrint('ChildrenScreen: add child failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler: $error')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void openAddChildForm() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AddChildSheet(
          firstNameController: firstNameController,
          lastNameController: lastNameController,
          birthDateController: birthDateController,
          groupNameController: groupNameController,
          parentUidController: parentUidController,
          notesController: notesController,
          saving: saving,
          onSave: () async {
            final access = await roleGuardService.loadAccess();
            if (!mounted || access == null) return;
            await addChild(access);
          },
        );
      },
    );
  }

  void openChildProfile(QueryDocumentSnapshot<Map<String, dynamic>> child) {
    Navigator.push(
      context,
      createPremiumRoute(
        ChildProfileScreen(authService: widget.authService, childId: child.id),
      ),
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    birthDateController.dispose();
    groupNameController.dispose();
    parentUidController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      authService: widget.authService,
      allowed: (access) => access.isAdmin || access.isTeacher,
      builder: (context, access) {
        return Scaffold(
          backgroundColor: const Color(0xFFFFF7ED),
          appBar: AppBar(title: const Text('Kinder')),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDBEAFE), Color(0xFFFCE7F3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.child_care_rounded, color: Color(0xFF2563EB)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Kinderverwaltung als Basis fuer Nachrichten, Portfolio, Berichte und Entwicklung.',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: access
                      .scopeCollection(
                        FirebaseFirestore.instance.collection('children'),
                      )
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Fehler beim Laden der Kinder'),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final children = snapshot.data!.docs;

                    if (children.isEmpty) return const _EmptyChildrenState();

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: children.length,
                      itemBuilder: (context, index) {
                        final child = children[index];
                        final data = child.data();

                        return _ChildListTile(
                          fullName: readString(data, 'fullName'),
                          groupName: readString(data, 'groupName'),
                          birthDate: formatBirthDate(data['birthDate']),
                          onTap: () => openChildProfile(child),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: access.canManageChildren
              ? FloatingActionButton.extended(
                  onPressed: openAddChildForm,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Kind hinzufuegen'),
                )
              : null,
        );
      },
    );
  }
}

class _AddChildSheet extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController birthDateController;
  final TextEditingController groupNameController;
  final TextEditingController parentUidController;
  final TextEditingController notesController;
  final bool saving;
  final VoidCallback onSave;

  const _AddChildSheet({
    required this.firstNameController,
    required this.lastNameController,
    required this.birthDateController,
    required this.groupNameController,
    required this.parentUidController,
    required this.notesController,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
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
        borderRadius: BorderRadius.circular(28),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kind hinzufuegen',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 18),
              _FormField(controller: firstNameController, label: 'Vorname'),
              _FormField(controller: lastNameController, label: 'Nachname'),
              _FormField(
                controller: birthDateController,
                label: 'Geburtsdatum',
                hint: 'z.B. 21.05.2021',
              ),
              _FormField(
                controller: groupNameController,
                label: 'Gruppe',
                hint: 'z.B. Sonnengruppe',
              ),
              _FormField(
                controller: parentUidController,
                label: 'Eltern UID optional',
              ),
              _FormField(
                controller: notesController,
                label: 'Notizen optional',
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: saving ? null : onSave,
                  child: saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Kind speichern'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;

  const _FormField({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _ChildListTile extends StatelessWidget {
  final String fullName;
  final String groupName;
  final String birthDate;
  final VoidCallback onTap;

  const _ChildListTile({
    required this.fullName,
    required this.groupName,
    required this.birthDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.child_care_rounded, color: Color(0xFF2563EB)),
        ),
        title: Text(
          fullName.isEmpty ? 'Unbenanntes Kind' : fullName,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          [
            if (groupName.isNotEmpty) groupName,
            if (birthDate.isNotEmpty) birthDate,
          ].join(' - '),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _EmptyChildrenState extends StatelessWidget {
  const _EmptyChildrenState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'Noch keine Kinder vorhanden.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      ),
    );
  }
}

String readString(Map<String, dynamic> data, String key) {
  final value = data[key];
  return value == null ? '' : value.toString();
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
