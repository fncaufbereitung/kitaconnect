import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/role_guard.dart';
import 'menu_screen.dart';

class AdminScreen extends StatelessWidget {
  final AuthService authService;

  const AdminScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      authService: authService,
      allowed: (access) => access.canManageUsers,
      builder: (context, access) => _AdminContent(authService: authService),
    );
  }
}

class _AdminContent extends StatefulWidget {
  final AuthService authService;

  const _AdminContent({required this.authService});

  @override
  State<_AdminContent> createState() => _AdminContentState();
}

class _AdminContentState extends State<_AdminContent> {
  final groupNameController = TextEditingController();
  bool loading = false;

  Future<void> createGroup() async {
    if (groupNameController.text.trim().isEmpty) return;

    setState(() => loading = true);

    await FirebaseFirestore.instance.collection('groups').add({
      'name': groupNameController.text.trim(),
      'createdAt': Timestamp.now(),
    });

    groupNameController.clear();

    if (mounted) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gruppe erstellt')));
    }
  }

  @override
  void dispose() {
    groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adminbereich')),
      body: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          children: [
            TextField(
              controller: groupNameController,
              decoration: const InputDecoration(
                labelText: 'Name der Gruppe',
                hintText: 'z.B. Sonnengruppe',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: loading ? null : createGroup,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Gruppe erstellen'),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.restaurant_menu),
                label: const Text('Menü bearbeiten'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MenuScreen(authService: widget.authService),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const _PendingUserApprovalsSection(),
            const SizedBox(height: 24),
            const Text(
              'Bestehende Gruppen',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final groups = snapshot.data!.docs;

                  if (groups.isEmpty) {
                    return const Center(
                      child: Text('Noch keine Gruppen vorhanden.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final data = groups[index].data() as Map<String, dynamic>;

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.groups),
                          title: Text(data['name'] ?? ''),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Kinder',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collectionGroup('children')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final children = snapshot.data!.docs;

                  if (children.isEmpty) {
                    return const Center(
                      child: Text('Noch keine Kinder vorhanden.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: children.length,
                    itemBuilder: (context, index) {
                      final data =
                          children[index].data() as Map<String, dynamic>;

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.child_care),
                          title: Text(data['childName'] ?? ''),
                          subtitle: Text(
                            'Gruppe: ${data['group'] ?? ''}\n'
                            'Geburtsdatum: ${data['birthDate'] ?? ''}',
                          ),
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
  }
}

class _PendingUserApprovalsSection extends StatelessWidget {
  const _PendingUserApprovalsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Benutzerfreigaben',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Fehler beim Laden der Benutzerfreigaben'),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data!.docs;

              if (users.isEmpty) {
                return const Center(
                  child: Text('Keine offenen Benutzerfreigaben.'),
                );
              }

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final data = user.data() as Map<String, dynamic>;

                  return _PendingUserApprovalTile(
                    userId: user.id,
                    name: readString(data, 'name'),
                    email: readString(data, 'email'),
                    initialRole: readRole(data['role']),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PendingUserApprovalTile extends StatefulWidget {
  final String userId;
  final String name;
  final String email;
  final String initialRole;

  const _PendingUserApprovalTile({
    required this.userId,
    required this.name,
    required this.email,
    required this.initialRole,
  });

  @override
  State<_PendingUserApprovalTile> createState() =>
      _PendingUserApprovalTileState();
}

class _PendingUserApprovalTileState extends State<_PendingUserApprovalTile> {
  static const roles = ['parent', 'teacher', 'admin'];

  late String selectedRole;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    selectedRole = roles.contains(widget.initialRole)
        ? widget.initialRole
        : 'parent';
  }

  Future<void> approveUser() async {
    await updateUserApproval({
      'status': 'active',
      'role': selectedRole,
      'approvedAt': FieldValue.serverTimestamp(),
    }, 'Benutzer freigeschaltet');
  }

  Future<void> rejectUser() async {
    await updateUserApproval({
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    }, 'Benutzer abgelehnt');
  }

  Future<void> updateUserApproval(
    Map<String, Object> values,
    String successMessage,
  ) async {
    if (saving) return;

    setState(() => saving = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update(values);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.name.isEmpty ? 'Unbenannter Benutzer' : widget.name,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              widget.email.isEmpty ? 'Keine E-Mail' : widget.email,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedRole,
              decoration: const InputDecoration(
                labelText: 'Rolle',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'parent', child: Text('parent')),
                DropdownMenuItem(value: 'teacher', child: Text('teacher')),
                DropdownMenuItem(value: 'admin', child: Text('admin')),
              ],
              onChanged: saving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => selectedRole = value);
                    },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: saving ? null : approveUser,
                    child: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: saving ? null : rejectUser,
                    child: const Text('Reject'),
                  ),
                ),
              ],
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

String readRole(dynamic value) {
  if (value is! String) return 'parent';
  final role = value.trim().toLowerCase();
  return _PendingUserApprovalTileState.roles.contains(role) ? role : 'parent';
}
