import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/role_guard.dart';

class MenuScreen extends StatefulWidget {
  final AuthService authService;

  const MenuScreen({super.key, required this.authService});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late final RoleGuardService roleGuardService;

  static const days = [
    {
      'id': 'monday',
      'day': 'Montag',
      'date': '27. Mai',
      'breakfast': 'Haferbrei mit Banane',
      'lunch': 'Gemuesesuppe und Frikadellen mit Kartoffelpueree',
      'snack': 'Joghurt mit Obst',
    },
    {
      'id': 'tuesday',
      'day': 'Dienstag',
      'date': '28. Mai',
      'breakfast': 'Vollkornbrot mit Kaese',
      'lunch': 'Nudeln mit Tomatensosse',
      'snack': 'Apfel und Kekse',
    },
    {
      'id': 'wednesday',
      'day': 'Mittwoch',
      'date': '29. Mai',
      'breakfast': 'Muesli mit Milch',
      'lunch': 'Reis mit Gemuese und Haehnchen',
      'snack': 'Banane',
    },
    {
      'id': 'thursday',
      'day': 'Donnerstag',
      'date': '30. Mai',
      'breakfast': 'Joghurt mit Muesli',
      'lunch': 'Ofenkartoffeln mit Salat',
      'snack': 'Frisches Obst',
    },
    {
      'id': 'friday',
      'day': 'Freitag',
      'date': '31. Mai',
      'breakfast': 'Ruehrei mit Brot',
      'lunch': 'Gemuesecremesuppe',
      'snack': 'Brezel und Tee',
    },
  ];

  @override
  void initState() {
    super.initState();
    roleGuardService = RoleGuardService(authService: widget.authService);
  }

  Future<void> editDay(
    UserAccess access,
    Map<String, String> day,
    Map<String, dynamic> currentData,
  ) async {
    if (!access.canEditContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine Berechtigung fuer das Menue.')),
      );
      return;
    }

    final breakfastController = TextEditingController(
      text: readValue(currentData, day, 'breakfast'),
    );
    final lunchController = TextEditingController(
      text: readValue(currentData, day, 'lunch'),
    );
    final snackController = TextEditingController(
      text: readValue(currentData, day, 'snack'),
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${day['day']} bearbeiten'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogField(
                  controller: breakfastController,
                  label: 'Fruehstueck',
                ),
                const SizedBox(height: 12),
                _DialogField(controller: lunchController, label: 'Mittagessen'),
                const SizedBox(height: 12),
                _DialogField(controller: snackController, label: 'Snack'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('weeklyMenu')
                    .doc(day['id'])
                    .set({
                      'day': day['day'],
                      'date': day['date'],
                      'breakfast': breakfastController.text.trim(),
                      'lunch': lunchController.text.trim(),
                      'snack': snackController.text.trim(),
                      ...access.contentScopeFields(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );

    breakfastController.dispose();
    lunchController.dispose();
    snackController.dispose();
  }

  String readValue(
    Map<String, dynamic> data,
    Map<String, String> fallback,
    String key,
  ) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) return value;
    return fallback[key] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserAccess?>(
      future: roleGuardService.loadAccess(),
      builder: (context, accessSnapshot) {
        if (accessSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final access = accessSnapshot.data;
        if (access == null) return const AccessDeniedScreen();

        return Scaffold(
          backgroundColor: const Color(0xFFF8F7FF),
          appBar: AppBar(
            title: const Text('Wochenmenue'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.black87,
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: access
                .scopeCollection(
                  FirebaseFirestore.instance.collection('weeklyMenu'),
                )
                .snapshots(),
            builder: (context, snapshot) {
              final docsById = <String, Map<String, dynamic>>{};
              if (snapshot.hasData) {
                for (final doc in snapshot.data!.docs) {
                  docsById[doc.id] = doc.data();
                }
              }

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFB8F7D4), Color(0xFFE9FFF1)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 38,
                          color: Colors.green,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Wochenmenue',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Hier sehen Eltern, was die Kinder in dieser Woche essen.',
                          style: TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final day in days)
                    _MenuDayCard(
                      day: day,
                      data: docsById[day['id']] ?? const {},
                      canEdit: access.canEditContent,
                      onEdit: () =>
                          editDay(access, day, docsById[day['id']] ?? const {}),
                      readValue: readValue,
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _MenuDayCard extends StatelessWidget {
  final Map<String, String> day;
  final Map<String, dynamic> data;
  final bool canEdit;
  final VoidCallback onEdit;
  final String Function(
    Map<String, dynamic> data,
    Map<String, String> fallback,
    String key,
  )
  readValue;

  const _MenuDayCard({
    required this.day,
    required this.data,
    required this.canEdit,
    required this.onEdit,
    required this.readValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9DDFF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  day['day']!,
                  style: const TextStyle(
                    color: Color(0xFF7B3FF2),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  day['date']!,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (canEdit)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_note_rounded),
                  tooltip: 'Menue bearbeiten',
                ),
            ],
          ),
          const SizedBox(height: 18),
          _mealRow(
            Icons.breakfast_dining,
            'Fruehstueck',
            readValue(data, day, 'breakfast'),
          ),
          _mealRow(
            Icons.lunch_dining,
            'Mittagessen',
            readValue(data, day, 'lunch'),
          ),
          _mealRow(Icons.cookie, 'Snack', readValue(data, day, 'snack')),
        ],
      ),
    );
  }

  static Widget _mealRow(IconData icon, String title, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFFF1CC),
            child: Icon(icon, color: Colors.orange),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _DialogField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
