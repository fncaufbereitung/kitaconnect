import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChildProfileScreen extends StatefulWidget {
  const ChildProfileScreen({super.key});

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  final childNameController = TextEditingController();
  final groupController = TextEditingController();
  final birthDateController = TextEditingController();
  final allergiesController = TextEditingController();
  bool loading = false;

  Future<void> saveChild() async {
    setState(() => loading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;

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
    final uid = FirebaseAuth.instance.currentUser!.uid;

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
                onPressed: loading ? null : saveChild,
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
