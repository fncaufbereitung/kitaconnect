import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/dashboard_card.dart';
import 'admin_screen.dart';
import 'child_profile_screen.dart';
import 'events_screen.dart';
import 'menu_screen.dart';
import 'messages_screen.dart';
import 'photos_screen.dart';
import 'profile_screen.dart';

Route createPremiumRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0.08, 0.04),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      final fadeAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      );

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(position: slideAnimation, child: child),
      );
    },
  );
}

class DashboardScreen extends StatefulWidget {
  final Future<Map<String, dynamic>?> Function() loadCurrentUserData;
  final WidgetBuilder dailyReportScreenBuilder;
  final AuthService authService;

  const DashboardScreen({
    super.key,
    required this.loadCurrentUserData,
    required this.dailyReportScreenBuilder,
    required this.authService,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    checkUserRole();
  }

  Future<void> checkUserRole() async {
    final data = await widget.loadCurrentUserData();
    final role = data?['role'] ?? 'parent';

    setState(() {
      isAdmin = role == 'admin';
    });
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
              debugPrint('DashboardScreen logout: pressed');
              await widget.authService.signOut();
              debugPrint('DashboardScreen logout: signOut returned');
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF38BDF8),
                    Color(0xFF8B5CF6),
                    Color(0xFFF472B6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF8B5CF6).withValues(alpha: 0.30),
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
                    child: Icon(
                      Icons.favorite,
                      size: 120,
                      color: Colors.white24,
                    ),
                  ),
                  const Positioned(
                    right: 20,
                    bottom: -10,
                    child: Icon(
                      Icons.child_care,
                      size: 90,
                      color: Colors.white24,
                    ),
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Willkommen zurück!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Alles Wichtige aus der Kita an einem Ort.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
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
            ),

            const SizedBox(height: 26),

            const Text(
              'Dashboard',
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
              children: [
                DashboardCard(
                  title: 'Kinderportfolio',
                  subtitle: 'Interne Dokumentation',
                  icon: Icons.auto_stories,
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      createPremiumRoute(
                        PhotosScreen(authService: widget.authService),
                      ),
                    );
                  },
                ),
                DashboardCard(
                  title: 'Wochenmenü',
                  subtitle: 'Essensplan',
                  icon: Icons.restaurant_menu,
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      createPremiumRoute(
                        MenuScreen(authService: widget.authService),
                      ),
                    );
                  },
                ),

                DashboardCard(
                  title: 'Nachrichten',
                  subtitle: 'Kommunikation',
                  icon: Icons.message,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      createPremiumRoute(
                        MessagesScreen(authService: widget.authService),
                      ),
                    );
                  },
                ),
                if (isAdmin)
                  DashboardCard(
                    title: 'Admin-Bereich',
                    subtitle: 'Für Erzieherinnen',
                    icon: Icons.admin_panel_settings,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        createPremiumRoute(
                          AdminScreen(authService: widget.authService),
                        ),
                      );
                    },
                  ),

                DashboardCard(
                  title: 'Events',
                  subtitle: 'Termine',
                  icon: Icons.event,
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      createPremiumRoute(
                        EventsScreen(authService: widget.authService),
                      ),
                    );
                  },
                ),

                DashboardCard(
                  title: 'Tagesbericht',
                  subtitle: 'Essen, Schlafen, Aktivität',
                  icon: Icons.assignment,
                  color: Colors.pink,
                  onTap: () {
                    Navigator.push(
                      context,
                      createPremiumRoute(
                        widget.dailyReportScreenBuilder(context),
                      ),
                    );
                  },
                ),

                DashboardCard(
                  title: 'Mein Kind',
                  subtitle: 'Profil & Infos',
                  icon: Icons.child_care,
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      createPremiumRoute(
                        ChildProfileScreen(authService: widget.authService),
                      ),
                    );
                  },
                ),

                if (isAdmin)
                  DashboardCard(
                    title: 'Admin',
                    subtitle: 'Verwaltung',
                    icon: Icons.admin_panel_settings,
                    color: Colors.deepPurple,
                    onTap: () {
                      Navigator.push(
                        context,
                        createPremiumRoute(
                          AdminScreen(authService: widget.authService),
                        ),
                      );
                    },
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
              setState(() {
                selectedIndex = index;
              });

              if (index == 1) {
                Navigator.push(
                  context,
                  createPremiumRoute(
                    PhotosScreen(authService: widget.authService),
                  ),
                );
              }

              if (index == 2) {
                Navigator.push(
                  context,
                  createPremiumRoute(
                    MessagesScreen(authService: widget.authService),
                  ),
                );
              }

              if (index == 3) {
                Navigator.push(
                  context,
                  createPremiumRoute(
                    ProfileScreen(
                      loadCurrentUserData: widget.loadCurrentUserData,
                      authService: widget.authService,
                    ),
                  ),
                );
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Start',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_stories_rounded),
                label: 'Portfolio',
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
