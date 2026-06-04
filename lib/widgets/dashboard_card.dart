import 'package:flutter/material.dart';

class DashboardCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const DashboardCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isPressed ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        elevation: isPressed ? 2 : 7,
        shadowColor: widget.color.withValues(alpha: 0.28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTapDown: (_) {
            setState(() {
              isPressed = true;
            });
          },
          onTapCancel: () {
            setState(() {
              isPressed = false;
            });
          },
          onTapUp: (_) {
            setState(() {
              isPressed = false;
            });
            widget.onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  widget.color.withValues(alpha: isPressed ? 0.16 : 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: isPressed ? 50 : 54,
                  height: isPressed ? 50 : 54,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 30),
                ),

                const Spacer(),

                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  widget.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
