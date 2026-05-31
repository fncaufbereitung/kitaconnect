import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/profile_option_tile.dart';
import 'child_profile_screen.dart';
import 'menu_screen.dart';

class ProfileScreen extends StatelessWidget {
  final Future<Map<String, dynamic>?> Function() loadCurrentUserData;

  const ProfileScreen({super.key, required this.loadCurrentUserData});

  String getRoleText(String role) {
    if (role == 'admin') return 'Administrator';
    if (role == 'teacher') return 'Erzieher/in';
    return 'Elternteil';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: loadCurrentUserData(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final name = data?['name'] ?? 'Benutzer';
        final email = data?['email'] ?? '';
        final role = data?['role'] ?? 'parent';

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFFF7ED),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Profil',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF60A5FA), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(45),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 50,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          getRoleText(role),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                ProfileOptionTile(
                  icon: Icons.restaurant_menu,
                  title: 'Wochenmenü',
                  subtitle: 'Speiseplan der Woche ansehen',
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MenuScreen()),
                    );
                  },
                ),

                const SizedBox(height: 24),

                ProfileOptionTile(
                  icon: Icons.child_care,
                  title: 'Mein Kind',
                  subtitle: 'Kinderprofil anzeigen',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChildProfileScreen(),
                      ),
                    );
                  },
                ),

                ProfileOptionTile(
                  icon: Icons.notifications,
                  title: 'Benachrichtigungen',
                  subtitle: 'Einstellungen für Push-Nachrichten',
                  color: Colors.orange,
                  onTap: () {},
                ),

                ProfileOptionTile(
                  icon: Icons.lock,
                  title: 'Sicherheit',
                  subtitle: 'Konto und Datenschutz',
                  color: Colors.blue,
                  onTap: () {},
                ),

                ProfileOptionTile(
                  icon: Icons.logout,
                  title: 'Abmelden',
                  subtitle: 'Vom Konto abmelden',
                  color: Colors.red,
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

