import 'package:flutter/material.dart';

import '../widgets/dashboard_card.dart';

class DemoDashboardScreen extends StatelessWidget {
  const DemoDashboardScreen({super.key});

  static const _kindergartenName = 'Kita Sonnenblume';
  static const _groupName = 'Sonnengruppe';
  static const _childName = 'Emma Schneider';
  static const _childAge = '4 Jahre';
  static const _teacherName = 'Frau Müller';

  static const _photoItems = [
    _DemoListItem(
      title: 'Morgenkreis mit Liedern',
      subtitle: 'Emma hat beim Begrüßungslied fröhlich mitgesungen.',
      icon: Icons.music_note_rounded,
    ),
    _DemoListItem(
      title: 'Bastelarbeit: Herbstbaum',
      subtitle: 'Mit Fingerfarben und buntem Papier gestaltet.',
      icon: Icons.palette_rounded,
    ),
    _DemoListItem(
      title: 'Spielen im Garten',
      subtitle: 'Balancieren, Sandküche und gemeinsames Rollenspiel.',
      icon: Icons.yard_rounded,
    ),
    _DemoListItem(
      title: 'Gemeinsames Frühstück',
      subtitle: 'Ruhige Tischrunde mit Obst, Brot und warmem Tee.',
      icon: Icons.local_cafe_rounded,
    ),
  ];

  static const _messages = [
    _DemoMessage(
      sender: _teacherName,
      message:
          'Emma hatte heute einen sehr schönen Tag. Besonders beim Basteln '
          'war sie konzentriert und stolz auf ihren Herbstbaum.',
      time: 'Heute, 14:10',
      icon: Icons.person_rounded,
    ),
    _DemoMessage(
      sender: 'Kita Leitung',
      message:
          'Bitte denken Sie morgen an wetterfeste Kleidung. Wir planen '
          'Gartenzeit, sofern das Wetter mitspielt.',
      time: 'Heute, 12:30',
      icon: Icons.campaign_rounded,
    ),
    _DemoMessage(
      sender: 'Erinnerung',
      message: 'Am Freitag findet unser Laternenbasteln statt.',
      time: 'Gestern, 16:45',
      icon: Icons.notifications_active_rounded,
    ),
  ];

  static const _weeklyMenu = [
    _MenuDay(
      day: 'Montag',
      breakfast: 'Vollkornbrot mit Frischkäse, Gurke',
      lunch: 'Gemüsepasta mit Tomatensauce',
      snack: 'Apfelschnitze und Kräutertee',
    ),
    _MenuDay(
      day: 'Dienstag',
      breakfast: 'Haferflocken mit Banane',
      lunch: 'Kartoffel-Möhren-Eintopf',
      snack: 'Naturjoghurt mit Beeren',
    ),
    _MenuDay(
      day: 'Mittwoch',
      breakfast: 'Dinkelbrötchen mit Käse',
      lunch: 'Hähnchenreis mit Erbsen',
      snack: 'Birne und Knäckebrot',
    ),
    _MenuDay(
      day: 'Donnerstag',
      breakfast: 'Obstsalat mit Hafercrunch',
      lunch: 'Linsencurry mit Reis',
      snack: 'Gemüsesticks mit Kräuterdip',
    ),
    _MenuDay(
      day: 'Freitag',
      breakfast: 'Brotzeit mit Tomate und Käse',
      lunch: 'Fischstäbchen mit Kartoffelpüree',
      snack: 'Milchreis mit Zimt',
    ),
  ];

  static const _events = [
    _DemoEvent(
      title: 'Laternenfest',
      date: 'Freitag, 13. November',
      description: 'Gemeinsamer Lichterumzug ab 16:30 Uhr im Kita-Garten.',
      icon: Icons.lightbulb_rounded,
    ),
    _DemoEvent(
      title: 'Ausflug in den Wildpark',
      date: 'Dienstag, 17. November',
      description:
          'Die Sonnengruppe besucht den Wildpark und beobachtet Tiere.',
      icon: Icons.park_rounded,
    ),
    _DemoEvent(
      title: 'Elternabend',
      date: 'Donnerstag, 19. November',
      description: 'Austausch zur Gruppenentwicklung und Jahresplanung.',
      icon: Icons.groups_rounded,
    ),
    _DemoEvent(
      title: 'Fotografentermin',
      date: 'Montag, 23. November',
      description: 'Einzel- und Gruppenfotos am Vormittag.',
      icon: Icons.camera_alt_rounded,
    ),
  ];

  static const _portfolioEntries = [
    _PortfolioEntry(
      area: 'Sprachentwicklung',
      note:
          'Emma erzählt im Morgenkreis zunehmend zusammenhängend und nutzt '
          'neue Begriffe sicher im Spiel.',
      icon: Icons.record_voice_over_rounded,
    ),
    _PortfolioEntry(
      area: 'Sozialverhalten',
      note:
          'Sie sucht aktiv Kontakt zu anderen Kindern, teilt Materialien und '
          'kann kleine Konflikte mit Unterstützung gut lösen.',
      icon: Icons.diversity_3_rounded,
    ),
    _PortfolioEntry(
      area: 'Kreativität',
      note:
          'Beim Gestalten probiert Emma Farben frei aus und entwickelt eigene '
          'Ideen für Formen und Muster.',
      icon: Icons.brush_rounded,
    ),
    _PortfolioEntry(
      area: 'Motorik',
      note:
          'Beim Balancieren und Klettern zeigt Emma mehr Sicherheit und Freude '
          'an neuen Bewegungsaufgaben.',
      icon: Icons.directions_run_rounded,
    ),
  ];

  static const _demoCards = [
    _DemoCardData(
      title: 'Fotos',
      subtitle: '4 Momente von heute',
      icon: Icons.photo_rounded,
      color: Colors.orange,
      type: _DemoSectionType.photos,
    ),
    _DemoCardData(
      title: 'Nachrichten',
      subtitle: '3 neue Hinweise',
      icon: Icons.chat_bubble_rounded,
      color: Colors.blue,
      type: _DemoSectionType.messages,
    ),
    _DemoCardData(
      title: 'Wochenmenü',
      subtitle: 'Montag bis Freitag',
      icon: Icons.restaurant_menu_rounded,
      color: Colors.green,
      type: _DemoSectionType.menu,
    ),
    _DemoCardData(
      title: 'Events',
      subtitle: '4 Termine',
      icon: Icons.event_rounded,
      color: Colors.teal,
      type: _DemoSectionType.events,
    ),
    _DemoCardData(
      title: 'Tagesbericht',
      subtitle: 'Emmas Tag',
      icon: Icons.assignment_rounded,
      color: Colors.pink,
      type: _DemoSectionType.dailyReport,
    ),
    _DemoCardData(
      title: 'Entwicklungsportfolio',
      subtitle: '4 Beobachtungen',
      icon: Icons.auto_stories_rounded,
      color: Colors.purple,
      type: _DemoSectionType.portfolio,
    ),
  ];

  void _showDemoDetail(BuildContext context, _DemoCardData card) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _DemoDetailSheet(
          card: card,
          child: _buildDetailContent(card.type),
        );
      },
    );
  }

  Widget _buildDetailContent(_DemoSectionType type) {
    switch (type) {
      case _DemoSectionType.photos:
        return _DemoList(items: _photoItems, color: Colors.orange);
      case _DemoSectionType.messages:
        return _MessagesList(messages: _messages);
      case _DemoSectionType.menu:
        return _WeeklyMenuList(menu: _weeklyMenu);
      case _DemoSectionType.events:
        return _EventsList(events: _events);
      case _DemoSectionType.dailyReport:
        return const _DailyReportPreview();
      case _DemoSectionType.portfolio:
        return _PortfolioList(entries: _portfolioEntries);
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
          'KitaConnect Demo',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _HeroSection(
              kindergartenName: _kindergartenName,
              groupName: _groupName,
              childName: _childName,
              childAge: _childAge,
            ),
            const SizedBox(height: 18),
            const _DemoBanner(),
            const SizedBox(height: 22),
            const _ProfileSummary(
              kindergartenName: _kindergartenName,
              groupName: _groupName,
              childName: _childName,
              childAge: _childAge,
              teacherName: _teacherName,
            ),
            const SizedBox(height: 26),
            const Text(
              'Kindergarten Demo',
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
                for (final card in _demoCards)
                  DashboardCard(
                    title: card.title,
                    subtitle: card.subtitle,
                    icon: card.icon,
                    color: card.color,
                    onTap: () => _showDemoDetail(context, card),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final String kindergartenName;
  final String groupName;
  final String childName;
  final String childAge;

  const _HeroSection({
    required this.kindergartenName,
    required this.groupName,
    required this.childName,
    required this.childAge,
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
            right: -18,
            top: -22,
            child: Icon(
              Icons.wb_sunny_rounded,
              size: 118,
              color: Colors.white24,
            ),
          ),
          const Positioned(
            right: 18,
            bottom: -12,
            child: Icon(Icons.child_care, size: 88, color: Colors.white24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Willkommen in der $kindergartenName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 29,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Demo-Profil: $childName – $groupName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    '$childAge · Premium KitaConnect',
                    style: const TextStyle(
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

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_rounded, color: Color(0xFFD97706)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Demo-Modus – keine echten Daten',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  final String kindergartenName;
  final String groupName;
  final String childName;
  final String childAge;
  final String teacherName;

  const _ProfileSummary({
    required this.kindergartenName,
    required this.groupName,
    required this.childName,
    required this.childAge,
    required this.teacherName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFFCE7F3),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.face_3_rounded,
              color: Color(0xFFDB2777),
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$childName, $childAge',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$groupName · $kindergartenName · $teacherName',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Color(0xFF6B7280),
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

class _DemoDetailSheet extends StatelessWidget {
  final _DemoCardData card;
  final Widget child;

  const _DemoDetailSheet({required this.card, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.86,
      ),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: card.color.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: card.color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(card.icon, color: card.color, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.title,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Text(
                          card.subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoList extends StatelessWidget {
  final List<_DemoListItem> items;
  final Color color;

  const _DemoList({required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          _PreviewTile(
            icon: item.icon,
            color: color,
            title: item.title,
            subtitle: item.subtitle,
          ),
      ],
    );
  }
}

class _MessagesList extends StatelessWidget {
  final List<_DemoMessage> messages;

  const _MessagesList({required this.messages});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final message in messages)
          _PreviewTile(
            icon: message.icon,
            color: Colors.blue,
            title: '${message.sender} · ${message.time}',
            subtitle: message.message,
          ),
      ],
    );
  }
}

class _WeeklyMenuList extends StatelessWidget {
  final List<_MenuDay> menu;

  const _WeeklyMenuList({required this.menu});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final day in menu)
          _SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.day,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 10),
                _MenuLine(label: 'Frühstück', value: day.breakfast),
                _MenuLine(label: 'Mittagessen', value: day.lunch),
                _MenuLine(label: 'Snack', value: day.snack),
              ],
            ),
          ),
      ],
    );
  }
}

class _EventsList extends StatelessWidget {
  final List<_DemoEvent> events;

  const _EventsList({required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final event in events)
          _PreviewTile(
            icon: event.icon,
            color: Colors.teal,
            title: '${event.title} · ${event.date}',
            subtitle: event.description,
          ),
      ],
    );
  }
}

class _DailyReportPreview extends StatelessWidget {
  const _DailyReportPreview();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _ReportMetric(
          icon: Icons.mood_rounded,
          label: 'Stimmung',
          value: 'fröhlich',
          color: Colors.amber,
        ),
        _ReportMetric(
          icon: Icons.bedtime_rounded,
          label: 'Schlaf',
          value: '45 Minuten',
          color: Colors.indigo,
        ),
        _ReportMetric(
          icon: Icons.restaurant_rounded,
          label: 'Essen',
          value: 'gut gegessen',
          color: Colors.green,
        ),
        _ReportMetric(
          icon: Icons.extension_rounded,
          label: 'Aktivitäten',
          value: 'Morgenkreis, Basteln, Gartenzeit',
          color: Colors.pink,
        ),
        _ReportMetric(
          icon: Icons.info_rounded,
          label: 'Hinweis',
          value: 'Bitte morgen Matschhose mitbringen.',
          color: Colors.orange,
        ),
      ],
    );
  }
}

class _PortfolioList extends StatelessWidget {
  final List<_PortfolioEntry> entries;

  const _PortfolioList({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final entry in entries)
          _PreviewTile(
            icon: entry.icon,
            color: Colors.purple,
            title: entry.area,
            subtitle: entry.note,
          ),
      ],
    );
  }
}

class _PreviewTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _PreviewTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.38,
                    color: Color(0xFF4B5563),
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

class _ReportMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ReportMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _PreviewTile(
      icon: icon,
      color: color,
      title: label,
      subtitle: value,
    );
  }
}

class _MenuLine extends StatelessWidget {
  final String label;
  final String value;

  const _MenuLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                height: 1.3,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;

  const _SoftCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }
}

enum _DemoSectionType { photos, messages, menu, events, dailyReport, portfolio }

class _DemoCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final _DemoSectionType type;

  const _DemoCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.type,
  });
}

class _DemoListItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const _DemoListItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _DemoMessage {
  final String sender;
  final String message;
  final String time;
  final IconData icon;

  const _DemoMessage({
    required this.sender,
    required this.message,
    required this.time,
    required this.icon,
  });
}

class _MenuDay {
  final String day;
  final String breakfast;
  final String lunch;
  final String snack;

  const _MenuDay({
    required this.day,
    required this.breakfast,
    required this.lunch,
    required this.snack,
  });
}

class _DemoEvent {
  final String title;
  final String date;
  final String description;
  final IconData icon;

  const _DemoEvent({
    required this.title,
    required this.date,
    required this.description,
    required this.icon,
  });
}

class _PortfolioEntry {
  final String area;
  final String note;
  final IconData icon;

  const _PortfolioEntry({
    required this.area,
    required this.note,
    required this.icon,
  });
}
