import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'child_profile_screen.dart';
import 'daily_reports_screen.dart';
import 'dashboard_screen.dart' show createPremiumRoute;
import 'events_screen.dart';
import 'menu_screen.dart';
import 'messages_screen.dart';
import 'photos_screen.dart';

const Color _ink = Color(0xFF334155);
const Color _mutedInk = Color(0xFF64748B);
const Color _lilac = Color(0xFFEDE7FF);
const Color _peach = Color(0xFFFFE8D6);
const Color _mint = Color(0xFFDFF7EA);
const Color _sky = Color(0xFFDDF1FF);
const Color _rose = Color(0xFFFFDCEB);
const Color _yellow = Color(0xFFFFF1A8);
const Color _purple = Color(0xFF7C3AED);
const Color _pink = Color(0xFFDB2777);
const Color _blue = Color(0xFF0284C7);
const Color _green = Color(0xFF059669);

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
    final featureCards = [
      _DashboardFeatureData(
        title: 'Fotos',
        subtitle: 'Kita-Momente',
        icon: Icons.photo_rounded,
        colors: const [Color(0xFFFFF7E8), _peach],
        accent: const Color(0xFFF97316),
        onTap: () => openFeature(PhotosScreen(authService: widget.authService)),
      ),
      _DashboardFeatureData(
        title: 'Nachrichten',
        subtitle: 'Kita-Team',
        icon: Icons.chat_bubble_rounded,
        colors: const [Color(0xFFEAF7FF), _sky],
        accent: _blue,
        onTap: () =>
            openFeature(MessagesScreen(authService: widget.authService)),
      ),
      _DashboardFeatureData(
        title: 'Wochenmenü',
        subtitle: 'Essensplan',
        icon: Icons.restaurant_menu_rounded,
        colors: const [Color(0xFFF0FFF8), _mint],
        accent: _green,
        onTap: () => openFeature(MenuScreen(authService: widget.authService)),
      ),
      _DashboardFeatureData(
        title: 'Kalender',
        subtitle: 'Termine',
        icon: Icons.event_rounded,
        colors: const [Color(0xFFFFFCEB), _yellow],
        accent: const Color(0xFFEAB308),
        onTap: () => openFeature(EventsScreen(authService: widget.authService)),
      ),
      _DashboardFeatureData(
        title: 'Mein Kind',
        subtitle: 'Profil & Infos',
        icon: Icons.child_care_rounded,
        colors: const [Color(0xFFF6EEFF), _lilac],
        accent: _purple,
        onTap: openAssignedChildren,
      ),
      _DashboardFeatureData(
        title: 'Tagesbericht',
        subtitle: 'Essen, Schlafen, Stimmung',
        icon: Icons.assignment_rounded,
        colors: const [Color(0xFFFFF2F7), _rose],
        accent: _pink,
        onTap: () =>
            openFeature(DailyReportsScreen(authService: widget.authService)),
      ),
      _DashboardFeatureData(
        title: 'Abwesenheiten',
        subtitle: 'Bald verfügbar',
        icon: Icons.event_busy_rounded,
        colors: const [Color(0xFFFFF5EB), Color(0xFFFFD7AD)],
        accent: const Color(0xFFEA580C),
        onTap: () => openFeature(
          const _ComingSoonScreen(
            title: 'Abwesenheiten',
            message:
                'Abwesenheiten können hier später übersichtlich verwaltet werden.',
            icon: Icons.event_busy_rounded,
          ),
        ),
      ),
      _DashboardFeatureData(
        title: 'Dokumente',
        subtitle: 'Portfolio',
        icon: Icons.folder_rounded,
        colors: const [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
        accent: const Color(0xFF4F46E5),
        onTap: () => openFeature(
          const _ComingSoonScreen(
            title: 'Entwicklung',
            message:
                'Das Entwicklungsportfolio wird hier später mit Beobachtungen und Lernmomenten gefüllt.',
            icon: Icons.auto_stories_rounded,
          ),
        ),
      ),
    ];

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'KitaConnect',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w900),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton.filledTonal(
              icon: const Icon(Icons.logout_rounded),
              color: _ink,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.72),
              ),
              onPressed: () async {
                debugPrint('ParentDashboardScreen logout: pressed');
                await widget.authService.signOut();
                debugPrint('ParentDashboardScreen logout: signOut returned');
              },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF7EA),
              Color(0xFFFFEEF8),
              Color(0xFFEFF7FF),
              Color(0xFFEFFFF6),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 380
                  ? 16.0
                  : 20.0;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  86,
                  horizontalPadding,
                  118,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HeroWelcomeCard(
                      title: 'Willkommen zurück!',
                      subtitle:
                          'Heute warten neue Kita-Momente, Nachrichten und Termine auf dich.',
                      icon: Icons.family_restroom_rounded,
                    ),
                    const SizedBox(height: 18),
                    _ChildProfileCard(onTap: openAssignedChildren),
                    const SizedBox(height: 26),
                    const Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Elternbereich',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: _ink,
                            ),
                          ),
                        ),
                        _DecorativeIcon(
                          icon: Icons.favorite_rounded,
                          color: _pink,
                          size: 22,
                        ),
                        SizedBox(width: 7),
                        _DecorativeIcon(
                          icon: Icons.auto_awesome_rounded,
                          color: _purple,
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Schneller Zugriff auf alle Kita-Momente.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _mutedInk,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ResponsiveFeatureGrid(items: featureCards),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: _ParentBottomNavigation(
        selectedIndex: selectedIndex,
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
      ),
    );
  }
}

class _HeroWelcomeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _HeroWelcomeCard({
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
          colors: [Color(0xFFFF8FB3), Color(0xFFA78BFA), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA78BFA).withValues(alpha: 0.30),
            blurRadius: 28,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const _DecorativeIcon(
            icon: Icons.auto_awesome_rounded,
            color: Colors.white24,
            size: 108,
            right: -20,
            top: -26,
          ),
          const _DecorativeIcon(
            icon: Icons.favorite_rounded,
            color: Colors.white30,
            size: 28,
            right: 92,
            top: 10,
          ),
          const _DecorativeIcon(
            icon: Icons.star_rounded,
            color: Colors.white38,
            size: 22,
            left: 128,
            bottom: 10,
          ),
          Positioned(
            right: -2,
            bottom: -8,
            child: _HeroIllustration(icon: icon),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 236),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Premium KitaConnect',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  final IconData icon;

  const _HeroIllustration({required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 122,
      height: 122,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.16),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          Positioned(
            left: 10,
            top: 15,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: _yellow,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 22,
            child: Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: _peach,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFFFFB7C5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 45, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ChildProfileCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ChildProfileCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.90)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF94A3B8).withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, 13),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_rose, _yellow],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(27),
                  boxShadow: [
                    BoxShadow(
                      color: _pink.withValues(alpha: 0.16),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.face_rounded,
                      color: Color(0xFFBE185D),
                      size: 38,
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dein Kind',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: const [
                        _ChildInfoChip(
                          icon: Icons.groups_rounded,
                          label: 'Gruppe',
                          color: _green,
                        ),
                        _ChildInfoChip(
                          icon: Icons.cake_rounded,
                          label: 'Alter',
                          color: _pink,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _lilac,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(Icons.arrow_forward_rounded, color: _purple),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ChildInfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveFeatureGrid extends StatelessWidget {
  final List<_DashboardFeatureData> items;

  const _ResponsiveFeatureGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 620 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: crossAxisCount == 2 ? 0.92 : 1.02,
          ),
          itemBuilder: (context, index) {
            return _PremiumFeatureCard(data: items[index]);
          },
        );
      },
    );
  }
}

class _DashboardFeatureData {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final Color accent;
  final VoidCallback onTap;

  const _DashboardFeatureData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.accent,
    required this.onTap,
  });
}

class _PremiumFeatureCard extends StatefulWidget {
  final _DashboardFeatureData data;

  const _PremiumFeatureCard({required this.data});

  @override
  State<_PremiumFeatureCard> createState() => _PremiumFeatureCardState();
}

class _PremiumFeatureCardState extends State<_PremiumFeatureCard> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isPressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOut,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: widget.data.accent.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTapDown: (_) => setState(() => isPressed = true),
            onTapCancel: () => setState(() => isPressed = false),
            onTapUp: (_) {
              setState(() => isPressed = false);
              widget.data.onTap();
            },
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.data.colors,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -16,
                    top: -18,
                    child: Icon(
                      Icons.favorite_rounded,
                      color: Colors.white.withValues(alpha: 0.34),
                      size: 68,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.84),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: widget.data.accent.withValues(
                                    alpha: 0.14,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.data.icon,
                              color: widget.data.accent,
                              size: 30,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: widget.data.accent.withValues(alpha: 0.30),
                            size: 22,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        width: 34,
                        height: 6,
                        decoration: BoxDecoration(
                          color: widget.data.accent.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.data.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.data.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _mutedInk,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DecorativeIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;

  const _DecorativeIcon({
    required this.icon,
    required this.color,
    required this.size,
    this.left,
    this.top,
    this.right,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final child = Icon(icon, color: color, size: size);

    if (left == null && top == null && right == null && bottom == null) {
      return child;
    }

    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: child,
    );
  }
}

class _ParentBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _ParentBottomNavigation({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withValues(alpha: 0.20),
              blurRadius: 26,
              offset: const Offset(0, 13),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            backgroundColor: Colors.white.withValues(alpha: 0.96),
            selectedItemColor: _purple,
            unselectedItemColor: const Color(0xFF94A3B8),
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            onTap: onTap,
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
