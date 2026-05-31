import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DailyReport {
  final String id;
  final String childName;
  final String date;
  final String mood;
  final String food;
  final String sleep;
  final String activities;
  final String notes;

  DailyReport({
    required this.id,
    required this.childName,
    required this.date,
    required this.mood,
    required this.food,
    required this.sleep,
    required this.activities,
    required this.notes,
  });

  factory DailyReport.fromMap(String id, Map<String, dynamic> data) {
    return DailyReport(
      id: id,
      childName: data['childName'] ?? '',
      date: data['date'] ?? '',
      mood: data['mood'] ?? '',
      food: data['food'] ?? '',
      sleep: data['sleep'] ?? '',
      activities: data['activities'] ?? '',
      notes: data['notes'] ?? '',
    );
  }
}

class DailyReportsScreen extends StatefulWidget {
  const DailyReportsScreen({super.key});

  @override
  State<DailyReportsScreen> createState() => _DailyReportsScreenState();
}

class _DailyReportsScreenState extends State<DailyReportsScreen> {
  final childNameController = TextEditingController();
  final moodController = TextEditingController();
  final foodController = TextEditingController();
  final sleepController = TextEditingController();
  final activitiesController = TextEditingController();
  final notesController = TextEditingController();

  bool loading = false;

  Future<void> addDailyReport() async {
    if (childNameController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final today = DateTime.now();

      await FirebaseFirestore.instance.collection('dailyReports').add({
        'childName': childNameController.text.trim(),
        'date': '${today.day}.${today.month}.${today.year}',
        'mood': moodController.text.trim(),
        'food': foodController.text.trim(),
        'sleep': sleepController.text.trim(),
        'activities': activitiesController.text.trim(),
        'notes': notesController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      childNameController.clear();
      moodController.clear();
      foodController.clear();
      sleepController.clear();
      activitiesController.clear();
      notesController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tagesbericht wurde gespeichert')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    }

    setState(() {
      loading = false;
    });
  }

  Widget buildInput({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget buildReportCard(DailyReport report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.childName,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(report.date, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 14),
          Text('😊 Stimmung: ${report.mood}'),
          const SizedBox(height: 6),
          Text('🍽 Essen: ${report.food}'),
          const SizedBox(height: 6),
          Text('😴 Schlaf: ${report.sleep}'),
          const SizedBox(height: 6),
          Text('🎨 Aktivitäten: ${report.activities}'),
          const SizedBox(height: 6),
          Text('📝 Notizen: ${report.notes}'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    childNameController.dispose();
    moodController.dispose();
    foodController.dispose();
    sleepController.dispose();
    activitiesController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFE3F2FD), Color(0xFFF3E5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Tagesberichte'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Neuen Tagesbericht erstellen',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    buildInput(
                      label: 'Name des Kindes',
                      controller: childNameController,
                    ),
                    const SizedBox(height: 12),
                    buildInput(label: 'Stimmung', controller: moodController),
                    const SizedBox(height: 12),
                    buildInput(label: 'Essen', controller: foodController),
                    const SizedBox(height: 12),
                    buildInput(label: 'Schlaf', controller: sleepController),
                    const SizedBox(height: 12),
                    buildInput(
                      label: 'Aktivitäten',
                      controller: activitiesController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    buildInput(
                      label: 'Notizen',
                      controller: notesController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: loading ? null : addDailyReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7E57C2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Speichern',
                                style: TextStyle(
                                  fontSize: 17,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('dailyReports')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Fehler beim Laden der Berichte');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Text(
                      'Noch keine Tagesberichte vorhanden.',
                      style: TextStyle(fontSize: 16),
                    );
                  }

                  return Column(
                    children: docs.map((doc) {
                      final report = DailyReport.fromMap(
                        doc.id,
                        doc.data() as Map<String, dynamic>,
                      );

                      return buildReportCard(report);
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
