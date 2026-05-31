import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const KitaConnectApp());
}
Future<Map<String, dynamic>?> getCurrentUserData() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return null;
  }

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (!doc.exists) {
    return null;
  }

  return doc.data();
}
class DailyReport {
  final String id;
  final String childName;
  final String date;
  final String mood;
  final String food;
  final String sleep;
  final String activities;
  final String notes;

  DailyReport({
    required this.id,
    required this.childName,
    required this.date,
    required this.mood,
    required this.food,
    required this.sleep,
    required this.activities,
    required this.notes,
  });

  factory DailyReport.fromMap(String id, Map<String, dynamic> data) {
    return DailyReport(
      id: id,
      childName: data['childName'] ?? '',
      date: data['date'] ?? '',
      mood: data['mood'] ?? '',
      food: data['food'] ?? '',
      sleep: data['sleep'] ?? '',
      activities: data['activities'] ?? '',
      notes: data['notes'] ?? '',
    );
  }
}
class KitaConnectApp extends StatelessWidget {
  const KitaConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KitaConnect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFFF4F7FB),
          foregroundColor: Color(0xFF1E293B),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return DashboardScreen(
            loadCurrentUserData: getCurrentUserData,
            dailyReportScreenBuilder: (_) => const DailyReportScreen(),
          );
        }

        return const WelcomeScreen();
      },
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFDBEAFE),
              Color(0xFFF8FAFC),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 115,
                  height: 115,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(34),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 25,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.child_care_rounded,
                    size: 70,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'KitaConnect',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Die moderne Verbindung\nzwischen Kita und Eltern',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.4,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 45),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text('Einloggen'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text('Konto erstellen'),
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  Future<void> login() async {
    try {
      setState(() => loading = true);

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardScreen(
              loadCurrentUserData: getCurrentUserData,
              dailyReportScreenBuilder: (_) => const DailyReportScreen(),
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Fehler beim Einloggen')),
        );
      }
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Einloggen')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(26),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.12),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 48,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 26),
            const Text(
              'Willkommen zurück',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 34),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'E-Mail',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Passwort',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: loading ? null : login,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Einloggen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  Future<void> register() async {
    try {
      setState(() => loading = true);

      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'role': 'parent',
        'kindergartenId': '',
'groupId': '',
        'createdAt': Timestamp.now(),
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardScreen(
              loadCurrentUserData: getCurrentUserData,
              dailyReportScreenBuilder: (_) => const DailyReportScreen(),
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Fehler')),
        );
      }
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konto erstellen')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(26),
        child: Column(
          children: [
            const SizedBox(height: 25),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.12),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                size: 48,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 26),
            const Text(
              'Neues Konto',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 34),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'E-Mail',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Passwort',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: loading ? null : register,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Konto erstellen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class DashboardGrid extends StatelessWidget {
  final List<Widget> children;

  const DashboardGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.05,
      crossAxisSpacing: 18,
      mainAxisSpacing: 18,
      children: children,
    );
  }
}

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();

  Future<void> addAnnouncement() async {
    if (titleController.text.trim().isEmpty ||
        contentController.text.trim().isEmpty) {
      return;
    }

    await FirebaseFirestore.instance.collection('announcements').add({
      'title': titleController.text.trim(),
      'content': contentController.text.trim(),
      'createdAt': Timestamp.now(),
    });

    titleController.clear();
    contentController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ankündigung erstellt')),
      );
    }
  }

  String formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day.toString().padLeft(2, '0')}.'
          '${date.month.toString().padLeft(2, '0')}.'
          '${date.year}';
    }
    return '';
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ankündigungen')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Titel',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Nachricht',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: addAnnouncement,
                child: const Text('Ankündigung speichern'),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('announcements')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Fehler beim Laden der Ankündigungen'),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final announcements = snapshot.data!.docs;

                  if (announcements.isEmpty) {
                    return const Center(
                      child: Text('Noch keine Ankündigungen vorhanden.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: announcements.length,
                    itemBuilder: (context, index) {
                      final data = announcements[index].data()
                          as Map<String, dynamic>;

                      final title = data['title'] ?? '';
                      final content = data['content'] ?? '';
                      final date = formatDate(data['createdAt']);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.20),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.20),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.campaign,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    date,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                content,
                                style: const TextStyle(
                                  color: Colors.white,
                                  height: 1.5,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  final childController = TextEditingController();
  final foodController = TextEditingController();
  final sleepController = TextEditingController();
  final moodController = TextEditingController();
  final notesController = TextEditingController();

  Future<void> saveReport() async {
    if (childController.text.trim().isEmpty) return;

    await FirebaseFirestore.instance.collection('daily_reports').add({
      'childName': childController.text.trim(),
      'food': foodController.text.trim(),
      'sleep': sleepController.text.trim(),
      'mood': moodController.text.trim(),
      'notes': notesController.text.trim(),
      'createdAt': Timestamp.now(),
    });

    childController.clear();
    foodController.clear();
    sleepController.clear();
    moodController.clear();
    notesController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tagesbericht gespeichert')),
      );
    }
  }

  @override
  void dispose() {
    childController.dispose();
    foodController.dispose();
    sleepController.dispose();
    moodController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tagesbericht')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: childController,
              decoration: const InputDecoration(
                labelText: 'Name des Kindes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: foodController,
              decoration: const InputDecoration(
                labelText: 'Essen',
                hintText: 'z.B. gut gegessen',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sleepController,
              decoration: const InputDecoration(
                labelText: 'Schlaf',
                hintText: 'z.B. 1 Stunde geschlafen',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: moodController,
              decoration: const InputDecoration(
                labelText: 'Stimmung',
                hintText: 'z.B. fröhlich',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notizen',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: saveReport,
                child: const Text('Bericht speichern'),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('daily_reports')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final reports = snapshot.data!.docs;

                  if (reports.isEmpty) {
                    return const Center(
                      child: Text('Noch keine Berichte vorhanden.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final data = reports[index].data()
                          as Map<String, dynamic>;

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.note_alt),
                          title: Text(data['childName'] ?? ''),
                          subtitle: Text(
                            'Essen: ${data['food'] ?? ''}\n'
                            'Schlaf: ${data['sleep'] ?? ''}\n'
                            'Stimmung: ${data['mood'] ?? ''}\n'
                            'Notizen: ${data['notes'] ?? ''}',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

  


