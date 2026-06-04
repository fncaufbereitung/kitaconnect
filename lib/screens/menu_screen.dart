import 'package:flutter/material.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final days = [
      {
        'day': 'Montag',
        'date': '27. Mai',
        'breakfast': 'Haferbrei mit Banane',
        'lunch': 'Gemüsesuppe und Frikadellen mit Kartoffelpüree',
        'snack': 'Joghurt mit Obst',
      },
      {
        'day': 'Dienstag',
        'date': '28. Mai',
        'breakfast': 'Vollkornbrot mit Käse',
        'lunch': 'Nudeln mit Tomatensoße',
        'snack': 'Apfel und Kekse',
      },
      {
        'day': 'Mittwoch',
        'date': '29. Mai',
        'breakfast': 'Müsli mit Milch',
        'lunch': 'Reis mit Gemüse und Hähnchen',
        'snack': 'Banane',
      },
      {
        'day': 'Donnerstag',
        'date': '30. Mai',
        'breakfast': 'Joghurt mit Müsli',
        'lunch': 'Ofenkartoffeln mit Salat',
        'snack': 'Frisches Obst',
      },
      {
        'day': 'Freitag',
        'date': '31. Mai',
        'breakfast': 'Rührei mit Brot',
        'lunch': 'Gemüsecremesuppe',
        'snack': 'Brezel und Tee',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        title: const Text('Wochenmenü'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
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
                Icon(Icons.restaurant_menu, size: 38, color: Colors.green),
                SizedBox(height: 12),
                Text(
                  'Wochenmenü',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
            Container(
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
                      Text(
                        day['date']!,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _mealRow(
                    Icons.breakfast_dining,
                    'Frühstück',
                    day['breakfast']!,
                  ),
                  _mealRow(Icons.lunch_dining, 'Mittagessen', day['lunch']!),
                  _mealRow(Icons.cookie, 'Snack', day['snack']!),
                ],
              ),
            ),
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
