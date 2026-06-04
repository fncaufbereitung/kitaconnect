import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'admin_screen.dart';
import 'children_screen.dart';
import 'daily_reports_screen.dart';
import 'dashboard_screen.dart' show createPremiumRoute;
import 'events_screen.dart';
import 'menu_screen.dart';
import 'messages_screen.dart';
import 'photos_screen.dart';
import 'teacher_requests_screen.dart';

const Color _ink = Color(0xFF334155);
const Color _mutedInk = Color(0xFF64748B);
const Color _peach = Color(0xFFFFE8D6);
const Color _mint = Color(0xFFDFF7EA);
const Color _sky = Color(0xFFDDF1FF);
const Color _yellow = Color(0xFFFFF1A8);
const Color _purple = Color(0xFF7C3AED);
const Color _pink = Color(0xFFDB2777);
const Color _blue = Color(0xFF0284C7);
const Color _green = Color(0xFF059669);

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
    final featureCards = [
      _TeacherFeatureData(
        title: widget.isAdmin ? 'Kinderverwaltung' : 'Kinder',
        subtitle: widget.isAdmin ? 'Kinder verwalten' : 'Profile & Gruppen',
        icon: Icons.child_care_rounded,
        colors: const [Color(0xFFF0E4FF), Color(0xFFDCC7FF)],
        accent: const Color(0xFF8B5CF6),
        onTap: () =>
            openFeature(ChildrenScreen(authService: widget.authService)),
      ),
      _TeacherFeatureData(
        title: 'Nachrichten senden',
        subtitle: 'Eltern informieren',
        icon: Icons.send_rounded,
        colors: const [Color(0xFFDDFCF3), Color(0xFFA7F3D0)],
        accent: const Color(0xFF0D9488),
        onTap: () =>
            openFeature(MessagesScreen(authService: widget.authService)),
      ),
      _TeacherFeatureData(
        title: 'Kinderportfolio',
        subtitle: 'Interne Dokumentation',
        icon: Icons.auto_stories_rounded,
        colors: const [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
        accent: const Color(0xFF0284C7),
        onTap: () => openFeature(PhotosScreen(authService: widget.authService)),
      ),
      _TeacherFeatureData(
        title: 'Tagesberichte',
        subtitle: 'Berichte erstellen',
        icon: Icons.assignment_rounded,
        colors: const [Color(0xFFFFE4F1), Color(0xFFFFB8D8)],
        accent: const Color(0xFFDB2777),
        onTap: () =>
            openFeature(DailyReportsScreen(authService: widget.authService)),
      ),
      _TeacherFeatureData(
        title: 'Wochenmenü bearbeiten',
        subtitle: 'Essensplan pflegen',
        icon: Icons.restaurant_menu_rounded,
        colors: const [Color(0xFFFFF1C2), Color(0xFFFFC878)],
        accent: const Color(0xFFF97316),
        onTap: () => openFeature(MenuScreen(authService: widget.authService)),
      ),
      _TeacherFeatureData(
        title: 'Events erstellen',
        subtitle: 'Termine planen',
        icon: Icons.event_rounded,
        colors: const [Color(0xFFFFE4EF), Color(0xFFFFA7C8)],
        accent: const Color(0xFFBE185D),
        onTap: () => openFeature(EventsScreen(authService: widget.authService)),
      ),
      _TeacherFeatureData(
        title: 'Elternmitteilungen',
        subtitle: 'Anfragen bearbeiten',
        icon: Icons.mark_email_unread_rounded,
        colors: const [Color(0xFFEAF7FF), Color(0xFFDDF1FF)],
        accent: _blue,
        onTap: () =>
            openFeature(TeacherRequestsScreen(authService: widget.authService)),
      ),
      if (widget.isAdmin)
        _TeacherFeatureData(
          title: 'Adminbereich',
          subtitle: 'Freigaben & Struktur',
          icon: Icons.admin_panel_settings_rounded,
          colors: const [Color(0xFFEDE9FE), Color(0xFFC4B5FD)],
          accent: const Color(0xFF6D28D9),
          onTap: () =>
              openFeature(AdminScreen(authService: widget.authService)),
        ),
    ];

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          areaTitle,
          style: const TextStyle(color: _ink, fontWeight: FontWeight.w900),
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
                debugPrint('TeacherDashboardScreen logout: pressed');
                await widget.authService.signOut();
                debugPrint('TeacherDashboardScreen logout: signOut returned');
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
              Color(0xFFEFFFF6),
              Color(0xFFEFF7FF),
              Color(0xFFFFEEF8),
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
                    _TeacherHeroCard(isAdmin: widget.isAdmin),
                    const SizedBox(height: 18),
                    _TeacherStatsCard(isAdmin: widget.isAdmin),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            areaTitle,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: _ink,
                            ),
                          ),
                        ),
                        const _DecorativeIcon(
                          icon: Icons.favorite_rounded,
                          color: _pink,
                          size: 22,
                        ),
                        const SizedBox(width: 7),
                        const _DecorativeIcon(
                          icon: Icons.auto_awesome_rounded,
                          color: _purple,
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Schneller Zugriff für den Kita-Alltag.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _mutedInk,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ResponsiveTeacherGrid(items: featureCards),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: _TeacherBottomNavigation(
        selectedIndex: selectedIndex,
        onTap: (index) {
          setState(() => selectedIndex = index);

          if (index == 1) {
            openFeature(MessagesScreen(authService: widget.authService));
          }
          if (index == 2) {
            openFeature(PhotosScreen(authService: widget.authService));
          }
          if (index == 3) {
            if (widget.isAdmin) {
              openFeature(AdminScreen(authService: widget.authService));
            } else {
              openFeature(ChildrenScreen(authService: widget.authService));
            }
          }
        },
        isAdmin: widget.isAdmin,
      ),
    );
  }
}

class _TeacherHeroCard extends StatelessWidget {
  final bool isAdmin;

  const _TeacherHeroCard({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          colors: [Color(0xFF34D399), Color(0xFF38BDF8), Color(0xFFA78BFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.30),
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
          const Positioned(
            right: -2,
            bottom: -8,
            child: _TeacherIllustration(),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 238),
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
                        Icons.verified_rounded,
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
                  isAdmin ? 'Willkommen im Adminbereich' : 'Willkommen im Team',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Kinder, Elternkommunikation und Kita-Alltag schnell im Blick.',
                  style: TextStyle(
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

class _TeacherIllustration extends StatelessWidget {
  const _TeacherIllustration();

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
            child: const Icon(
              Icons.school_rounded,
              size: 45,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherStatsCard extends StatelessWidget {
  final bool isAdmin;

  const _TeacherStatsCard({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                colors: [_mint, _sky],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(27),
              boxShadow: [
                BoxShadow(
                  color: _green.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              isAdmin
                  ? Icons.admin_panel_settings_rounded
                  : Icons.groups_rounded,
              color: isAdmin ? _purple : _green,
              size: 38,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAdmin ? 'Admin-Übersicht' : 'Team-Übersicht',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
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
                    _TeacherInfoChip(
                      icon: Icons.child_care_rounded,
                      label: 'Kinder',
                      color: _purple,
                    ),
                    _TeacherInfoChip(
                      icon: Icons.chat_bubble_rounded,
                      label: 'Eltern',
                      color: _blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TeacherInfoChip({
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

class _ResponsiveTeacherGrid extends StatelessWidget {
  final List<_TeacherFeatureData> items;

  const _ResponsiveTeacherGrid({required this.items});

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
            return _TeacherFeatureCard(data: items[index]);
          },
        );
      },
    );
  }
}

class _TeacherFeatureData {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final Color accent;
  final VoidCallback onTap;

  const _TeacherFeatureData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.accent,
    required this.onTap,
  });
}

class _TeacherFeatureCard extends StatefulWidget {
  final _TeacherFeatureData data;

  const _TeacherFeatureCard({required this.data});

  @override
  State<_TeacherFeatureCard> createState() => _TeacherFeatureCardState();
}

class _TeacherFeatureCardState extends State<_TeacherFeatureCard> {
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
              color: widget.data.accent.withValues(alpha: 0.24),
              blurRadius: 22,
              offset: const Offset(0, 13),
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
                              color: Colors.white.withValues(alpha: 0.88),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: widget.data.accent.withValues(
                                    alpha: 0.22,
                                  ),
                                  blurRadius: 14,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.data.icon,
                              color: widget.data.accent,
                              size: 34,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: widget.data.accent.withValues(alpha: 0.42),
                            size: 24,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        width: 34,
                        height: 6,
                        decoration: BoxDecoration(
                          color: widget.data.accent.withValues(alpha: 0.34),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.data.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 16.5,
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
                          color: Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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

class _TeacherBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool isAdmin;

  const _TeacherBottomNavigation({
    required this.selectedIndex,
    required this.onTap,
    required this.isAdmin,
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
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Start',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_rounded),
                label: 'Nachrichten',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.auto_stories_rounded),
                label: 'Portfolio',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  isAdmin
                      ? Icons.admin_panel_settings_rounded
                      : Icons.child_care_rounded,
                ),
                label: isAdmin ? 'Admin' : 'Kinder',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
