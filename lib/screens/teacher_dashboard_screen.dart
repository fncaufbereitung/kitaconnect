import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/dashboard_card.dart';
import 'admin_screen.dart';
import 'children_screen.dart';
import 'daily_reports_screen.dart';
import 'dashboard_screen.dart' show createPremiumRoute;
import 'events_screen.dart';
import 'menu_screen.dart';
import 'messages_screen.dart';
import 'photos_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  final AuthService authService;
  final bool isAdmin;

  const TeacherDashboardScreen({
    super.key,
    required this.authService,
    this.isAdmin = false,
  });

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  int selectedIndex = 0;

  void openFeature(Widget screen) {
    Navigator.push(context, createPremiumRoute(screen));
  }

  @override
  Widget build(BuildContext context) {
    final areaTitle = widget.isAdmin ? 'Adminbereich' : 'Erzieherbereich';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          areaTitle,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              debugPrint('TeacherDashboardScreen logout: pressed');
              await widget.authService.signOut();
              debugPrint('TeacherDashboardScreen logout: signOut returned');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TeacherHero(isAdmin: widget.isAdmin),
            const SizedBox(height: 26),
            Text(
              areaTitle,
              style: const TextStyle(
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
                  title: 'Kinder',
                  subtitle: 'Profile & Gruppen',
                  icon: Icons.child_care_rounded,
                  color: Colors.purple,
                  onTap: () => openFeature(
                    ChildrenScreen(authService: widget.authService),
                  ),
                ),
                DashboardCard(
                  title: 'Nachrichten senden',
                  subtitle: 'Eltern informieren',
                  icon: Icons.send_rounded,
                  color: Colors.blue,
                  onTap: () => openFeature(
                    MessagesScreen(authService: widget.authService),
                  ),
                ),
                DashboardCard(
                  title: 'Fotos hochladen',
                  subtitle: 'Kita-Momente teilen',
                  icon: Icons.add_a_photo_rounded,
                  color: Colors.orange,
                  onTap: () => openFeature(
                    PhotosScreen(authService: widget.authService),
                  ),
                ),
                DashboardCard(
                  title: 'Tagesberichte',
                  subtitle: 'Berichte erstellen',
                  icon: Icons.assignment_rounded,
                  color: Colors.pink,
                  onTap: () => openFeature(const DailyReportsScreen()),
                ),
                DashboardCard(
                  title: 'Wochenmenü bearbeiten',
                  subtitle: 'Essensplan pflegen',
                  icon: Icons.restaurant_menu_rounded,
                  color: Colors.green,
                  onTap: () => openFeature(const MenuScreen()),
                ),
                DashboardCard(
                  title: 'Events erstellen',
                  subtitle: 'Termine planen',
                  icon: Icons.event_rounded,
                  color: Colors.teal,
                  onTap: () => openFeature(const EventsScreen()),
                ),
                DashboardCard(
                  title: 'Gruppen',
                  subtitle: 'Kita-Struktur',
                  icon: Icons.groups_rounded,
                  color: Colors.indigo,
                  onTap: () => openFeature(const AdminScreen()),
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
                openFeature(MessagesScreen(authService: widget.authService));
              }
              if (index == 2) {
                openFeature(PhotosScreen(authService: widget.authService));
              }
              if (index == 3) {
                openFeature(const AdminScreen());
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Start',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_rounded),
                label: 'Nachrichten',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.photo_rounded),
                label: 'Fotos',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.admin_panel_settings_rounded),
                label: 'Admin',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherHero extends StatelessWidget {
  final bool isAdmin;

  const _TeacherHero({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          colors: [Color(0xFF14B8A6), Color(0xFF3B82F6), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -16,
            top: -20,
            child: Icon(Icons.auto_awesome, size: 118, color: Colors.white24),
          ),
          const Positioned(
            right: 18,
            bottom: -10,
            child: Icon(Icons.school_rounded, size: 90, color: Colors.white24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAdmin ? 'Willkommen im Adminbereich' : 'Willkommen im Team',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Kinder, Elternkommunikation und Kita-Alltag schnell im Blick.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Icon(Icons.verified_rounded, color: Colors.white),
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
