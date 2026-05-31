import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'menu_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
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
                    MaterialPageRoute(builder: (_) => const MenuScreen()),
                  );
                },
              ),
            ),
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
