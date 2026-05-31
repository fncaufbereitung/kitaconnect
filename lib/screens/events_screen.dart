import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final titleController = TextEditingController();
  final dateController = TextEditingController();

  Future<void> addEvent() async {
    if (titleController.text.trim().isEmpty ||
        dateController.text.trim().isEmpty) {
      return;
    }

    await FirebaseFirestore.instance.collection('events').add({
      'title': titleController.text.trim(),
      'date': dateController.text.trim(),
      'createdAt': Timestamp.now(),
    });

    titleController.clear();
    dateController.clear();

    if (mounted) {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Termine')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
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
                onPressed: addEvent,
                child: const Text('Termin speichern'),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final events = snapshot.data!.docs;

                  if (events.isEmpty) {
                    return const Center(
                      child: Text('Noch keine Termine vorhanden.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final data = events[index].data() as Map<String, dynamic>;
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
  }
}
