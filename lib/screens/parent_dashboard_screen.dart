import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/dashboard_card.dart';
import 'child_profile_screen.dart';
import 'daily_reports_screen.dart';
import 'dashboard_screen.dart' show createPremiumRoute;
import 'events_screen.dart';
import 'menu_screen.dart';
import 'messages_screen.dart';
import 'photos_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  final AuthService authService;

  const ParentDashboardScreen({super.key, required this.authService});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  int selectedIndex = 0;

  void openFeature(Widget screen) {
    Navigator.push(context, createPremiumRoute(screen));
  }

  Future<void> openAssignedChildren() async {
    final uid = widget.authService.currentUser?.uid;

    if (uid == null) {
      debugPrint('ParentDashboardScreen: parent child lookup skipped, no uid');
      return;
    }

    debugPrint('ParentDashboardScreen: parent child lookup for uid=$uid');

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('children')
          .where('parentIds', arrayContains: uid)
          .get();

      debugPrint(
        'ParentDashboardScreen: parent child lookup found '
        '${snapshot.docs.length} children',
      );

      if (!mounted) return;

      if (snapshot.docs.isEmpty) {
        openFeature(const _NoAssignedChildScreen());
        return;
      }

      if (snapshot.docs.length == 1) {
        final child = snapshot.docs.first;
        debugPrint(
          'ParentDashboardScreen: opening child profile childId=${child.id}',
        );
        openFeature(
          ChildProfileScreen(
            authService: widget.authService,
            childId: child.id,
          ),
        );
        return;
      }

      openFeature(
        _ParentChildrenListScreen(
          authService: widget.authService,
          children: snapshot.docs,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('ParentDashboardScreen: parent child lookup failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'KitaConnect',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              debugPrint('ParentDashboardScreen logout: pressed');
              await widget.authService.signOut();
              debugPrint('ParentDashboardScreen logout: signOut returned');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DashboardHero(
              title: 'Willkommen zurück!',
              subtitle: 'Alles Wichtige rund um dein Kind an einem Ort.',
              icon: Icons.family_restroom_rounded,
            ),
            const SizedBox(height: 26),
            const Text(
              'Elternbereich',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              childAspectRatio: 0.96,
              children: [
                DashboardCard(
                  title: 'Mein Kind',
                  subtitle: 'Profil & Infos',
                  icon: Icons.child_care_rounded,
                  color: Colors.purple,
                  onTap: openAssignedChildren,
                ),
                DashboardCard(
                  title: 'Nachrichten',
                  subtitle: 'Kita-Team',
                  icon: Icons.chat_bubble_rounded,
                  color: Colors.blue,
                  onTap: () => openFeature(
                    MessagesScreen(authService: widget.authService),
                  ),
                ),
                DashboardCard(
                  title: 'Fotos',
                  subtitle: 'Kita-Momente',
                  icon: Icons.photo_rounded,
                  color: Colors.orange,
                  onTap: () => openFeature(
                    PhotosScreen(authService: widget.authService),
                  ),
                ),
                DashboardCard(
                  title: 'Tagesbericht',
                  subtitle: 'Essen, Schlafen, Stimmung',
                  icon: Icons.assignment_rounded,
                  color: Colors.pink,
                  onTap: () => openFeature(const DailyReportsScreen()),
                ),
                DashboardCard(
                  title: 'Wochenmenü',
                  subtitle: 'Essensplan',
                  icon: Icons.restaurant_menu_rounded,
                  color: Colors.green,
                  onTap: () => openFeature(const MenuScreen()),
                ),
                DashboardCard(
                  title: 'Events',
                  subtitle: 'Termine',
                  icon: Icons.event_rounded,
                  color: Colors.teal,
                  onTap: () => openFeature(const EventsScreen()),
                ),
                DashboardCard(
                  title: 'Entwicklung',
                  subtitle: 'Portfolio',
                  icon: Icons.auto_stories_rounded,
                  color: Colors.indigo,
                  onTap: () => openFeature(
                    const _ComingSoonScreen(
                      title: 'Entwicklung',
                      message:
                          'Das Entwicklungsportfolio wird hier später mit Beobachtungen und Lernmomenten gefüllt.',
                      icon: Icons.auto_stories_rounded,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF7C3AED),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            onTap: (index) {
              setState(() => selectedIndex = index);

              if (index == 1) {
                openFeature(PhotosScreen(authService: widget.authService));
              }
              if (index == 2) {
                openFeature(MessagesScreen(authService: widget.authService));
              }
              if (index == 3) {
                openAssignedChildren();
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Start',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.photo_rounded),
                label: 'Fotos',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_rounded),
                label: 'Nachrichten',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _DashboardHero({
    required this.title,
    required this.subtitle,
    required this.icon,
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
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.favorite, size: 120, color: Colors.white24),
          ),
          Positioned(
            right: 18,
            bottom: -8,
            child: Icon(icon, size: 90, color: Colors.white24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Premium KitaConnect',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComingSoonScreen extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const _ComingSoonScreen({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(icon, size: 48, color: const Color(0xFF2563EB)),
              ),
              const SizedBox(height: 22),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParentChildrenListScreen extends StatelessWidget {
  final AuthService authService;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> children;

  const _ParentChildrenListScreen({
    required this.authService,
    required this.children,
  });

  void openChild(BuildContext context, QueryDocumentSnapshot child) {
    debugPrint(
      'ParentDashboardScreen: opening child profile childId=${child.id}',
    );
    Navigator.push(
      context,
      createPremiumRoute(
        ChildProfileScreen(authService: authService, childId: child.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      appBar: AppBar(title: const Text('Meine Kinder')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: children.length,
        itemBuilder: (context, index) {
          final child = children[index];
          final data = child.data();
          final fullName = readString(data, 'fullName');
          final groupName = readString(data, 'groupName');
          final birthDate = formatBirthDate(data['birthDate']);

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
                child: const Icon(
                  Icons.child_care_rounded,
                  color: Color(0xFF2563EB),
                ),
              ),
              title: Text(
                fullName.isEmpty ? 'Kindprofil' : fullName,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                [
                  if (groupName.isNotEmpty) groupName,
                  if (birthDate.isNotEmpty) birthDate,
                ].join(' · '),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => openChild(context, child),
            ),
          );
        },
      ),
    );
  }
}

class _NoAssignedChildScreen extends StatelessWidget {
  const _NoAssignedChildScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      appBar: AppBar(title: const Text('Mein Kind')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.child_care_rounded,
                  size: 48,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Noch kein Kind zugeordnet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Sobald die Kita ein Kind mit deinem Elternkonto verbindet, erscheint das Profil hier.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
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
