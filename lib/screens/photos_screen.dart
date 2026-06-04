import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/role_guard.dart';

const Color _ink = Color(0xFF334155);
const Color _mutedInk = Color(0xFF64748B);
const Color _peach = Color(0xFFFFE8D6);
const Color _mint = Color(0xFFDFF7EA);
const Color _sky = Color(0xFFDDF1FF);
const Color _purple = Color(0xFF7C3AED);

class PhotosScreen extends StatefulWidget {
  final AuthService authService;

  const PhotosScreen({super.key, required this.authService});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  final childIdController = TextEditingController();
  final childNameController = TextEditingController();
  final groupIdController = TextEditingController();
  final groupNameController = TextEditingController();

  bool uploading = false;
  late final RoleGuardService roleGuardService;
  late Future<UserAccess?> accessFuture;

  @override
  void initState() {
    super.initState();
    roleGuardService = RoleGuardService(authService: widget.authService);
    accessFuture = roleGuardService.loadAccess();
  }

  Future<void> uploadPhoto(UserAccess access) async {
    if (!access.canEditContent || access.isParent) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keine Berechtigung zum Hochladen.')),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (pickedFile == null) return;

    setState(() => uploading = true);

    try {
      final uid = widget.authService.currentUser!.uid;
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('kita_photos')
          .child('$fileName.jpg');

      final bytes = await pickedFile.readAsBytes();

      await storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final imageUrl = await storageRef.getDownloadURL();
      final childId = childIdController.text.trim();
      final childName = childNameController.text.trim();
      final groupId = groupIdController.text.trim();
      final groupName = groupNameController.text.trim();

      await FirebaseFirestore.instance.collection('photos').add({
        'imageUrl': imageUrl,
        'title': 'Kinderportfolio',
        'caption': 'Interne Dokumentation',
        'uploadedBy': uid,
        ...access.contentScopeFields(),
        'childId': childId,
        'childName': childName,
        'groupId': groupId,
        'groupName': groupName,
        'childIds': childId.isEmpty ? access.childIds : [childId],
        'groupIds': groupId.isEmpty ? access.groupIds : [groupId],
        'createdAt': Timestamp.now(),
      });

      debugPrint('PhotosScreen: portfolio photo uploaded by uid=$uid');

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Portfolio-Eintrag gespeichert')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> loadPortfolio(
    UserAccess access,
  ) async {
    final collection = FirebaseFirestore.instance.collection('photos');

    if (access.isAdmin) {
      final snapshot = await collection.get();
      final docs = snapshot.docs;
      sortPortfolio(docs);
      return docs;
    }

    final queries = <Future<QuerySnapshot<Map<String, dynamic>>>>[
      collection.where('uploadedBy', isEqualTo: access.uid).get(),
    ];

    if (access.groupIds.isNotEmpty) {
      queries.add(
        collection
            .where(
              'groupIds',
              arrayContainsAny: access.groupIds.take(30).toList(),
            )
            .get(),
      );
    }

    if (access.childIds.isNotEmpty) {
      queries.add(
        collection
            .where(
              'childIds',
              arrayContainsAny: access.childIds.take(30).toList(),
            )
            .get(),
      );
    }

    final snapshots = await Future.wait(queries);
    final docsById = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

    for (final snapshot in snapshots) {
      for (final doc in snapshot.docs) {
        docsById[doc.id] = doc;
      }
    }

    final docs = docsById.values.toList();
    sortPortfolio(docs);
    return docs;
  }

  void sortPortfolio(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    docs.sort((a, b) {
      return readCreatedAtMillis(
        b.data(),
      ).compareTo(readCreatedAtMillis(a.data()));
    });
  }

  int readCreatedAtMillis(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) return createdAt.millisecondsSinceEpoch;
    return 0;
  }

  String getStringValue(QueryDocumentSnapshot doc, String key) {
    final data = doc.data() as Map<String, dynamic>;
    final value = data[key];
    if (value == null) return '';
    return value.toString();
  }

  @override
  void dispose() {
    childIdController.dispose();
    childNameController.dispose();
    groupIdController.dispose();
    groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserAccess?>(
      future: accessFuture,
      builder: (context, accessSnapshot) {
        if (accessSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final access = accessSnapshot.data;
        if (access == null) return const AccessDeniedScreen();
        if (access.isParent) return const _PortfolioAccessDeniedScreen();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Kinderportfolio'),
            actions: [
              IconButton(
                tooltip: 'Portfolio-Foto hochladen',
                icon: uploading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_a_photo),
                onPressed: uploading ? null : () => uploadPhoto(access),
              ),
            ],
          ),
          body: Column(
            children: [
              _PortfolioInfoForm(
                childIdController: childIdController,
                childNameController: childNameController,
                groupIdController: groupIdController,
                groupNameController: groupNameController,
              ),
              Expanded(
                child:
                    FutureBuilder<
                      List<QueryDocumentSnapshot<Map<String, dynamic>>>
                    >(
                      future: loadPortfolio(access),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          debugPrint(
                            'PhotosScreen: portfolio load failed: ${snapshot.error}',
                          );
                          return const Center(
                            child: Text('Fehler beim Laden des Portfolios'),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final photos = snapshot.data ?? const [];

                        if (photos.isEmpty) {
                          return const Center(
                            child: Text(
                              'Noch keine Portfolio-Eintraege vorhanden.',
                            ),
                          );
                        }

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final crossAxisCount = width >= 1050
                                ? 4
                                : width >= 720
                                ? 3
                                : width >= 460
                                ? 2
                                : 1;

                            return GridView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                18,
                                18,
                                28,
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 18,
                                    mainAxisSpacing: 18,
                                    childAspectRatio: crossAxisCount == 1
                                        ? 0.95
                                        : 0.72,
                                  ),
                              itemCount: photos.length,
                              itemBuilder: (context, index) {
                                final photo = photos[index];
                                return _buildPhotoCard(context, photo, index);
                              },
                            );
                          },
                        );
                      },
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotoCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> photo,
    int index,
  ) {
    final imageUrl = getStringValue(photo, 'imageUrl');
    final title = getStringValue(photo, 'title');
    final caption = getStringValue(photo, 'caption');
    final childName = getStringValue(photo, 'childName');
    final groupName = getStringValue(photo, 'groupName');
    final gradientColors = _cardGradient(index);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.34),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 7,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(color: Colors.white),
                      child: imageUrl.isEmpty
                          ? const _PhotoPlaceholder(
                              icon: Icons.image_not_supported_rounded,
                            )
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const _PhotoPlaceholder(
                                      icon: Icons.photo_rounded,
                                      showProgress: true,
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return const _PhotoPlaceholder(
                                  icon: Icons.broken_image_rounded,
                                );
                              },
                            ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 12, 6, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.isEmpty ? 'Kinderportfolio' : title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 7),
                        if (childName.isNotEmpty)
                          Text(
                            groupName.isEmpty
                                ? childName
                                : '$childName - $groupName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _purple,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        if (childName.isNotEmpty) const SizedBox(height: 5),
                        Expanded(
                          child: Text(
                            caption.isEmpty ? 'Interne Dokumentation' : caption,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _mutedInk,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _PhotoActionButton(
                              icon: Icons.edit_note_rounded,
                              label: 'Bearbeiten',
                              foreground: _purple,
                              background: Colors.white,
                              onPressed: () {
                                final descriptionController =
                                    TextEditingController(
                                      text: getStringValue(photo, 'caption'),
                                    );

                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text(
                                        'Dokumentation bearbeiten',
                                      ),
                                      content: TextField(
                                        controller: descriptionController,
                                        maxLines: 4,
                                        decoration: const InputDecoration(
                                          hintText:
                                              'Interne Dokumentation eingeben...',
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Abbrechen'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            await FirebaseFirestore.instance
                                                .collection('photos')
                                                .doc(photo.id)
                                                .update({
                                                  'caption':
                                                      descriptionController.text
                                                          .trim(),
                                                });

                                            if (context.mounted) {
                                              Navigator.pop(context);
                                            }
                                          },
                                          child: const Text('Speichern'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                            _PhotoActionButton(
                              icon: Icons.download_rounded,
                              label: 'Download',
                              foreground: const Color(0xFF0284C7),
                              background: Colors.white.withValues(alpha: 0.82),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Download-Funktion wird als naechstes aktiviert',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _cardGradient(int index) {
    const gradients = [
      [Color(0xFFFFF6E7), _peach],
      [Color(0xFFF0FFF8), _mint],
      [Color(0xFFF1F8FF), _sky],
      [Color(0xFFFFF2F7), Color(0xFFFFDCEB)],
    ];

    return gradients[index % gradients.length];
  }
}

class _PortfolioInfoForm extends StatelessWidget {
  final TextEditingController childIdController;
  final TextEditingController childNameController;
  final TextEditingController groupIdController;
  final TextEditingController groupNameController;

  const _PortfolioInfoForm({
    required this.childIdController,
    required this.childNameController,
    required this.groupIdController,
    required this.groupNameController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF94A3B8).withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_stories_rounded, color: _purple),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kinderportfolio',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Interne Dokumentation - Nur für Erzieher/Admin sichtbar',
            style: TextStyle(
              color: _mutedInk,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PortfolioField(
                controller: childNameController,
                label: 'Kind Name',
              ),
              _PortfolioField(controller: childIdController, label: 'Kind ID'),
              _PortfolioField(
                controller: groupNameController,
                label: 'Gruppe Name',
              ),
              _PortfolioField(
                controller: groupIdController,
                label: 'Gruppe ID',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortfolioField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _PortfolioField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _PortfolioAccessDeniedScreen extends StatelessWidget {
  const _PortfolioAccessDeniedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      appBar: AppBar(title: const Text('Kinderportfolio')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Color(0xFFDC2626),
                  size: 46,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Kein Zugriff auf das Portfolio',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final IconData icon;
  final bool showProgress;

  const _PhotoPlaceholder({required this.icon, this.showProgress = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: showProgress
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Icon(icon, size: 46, color: const Color(0xFF94A3B8)),
      ),
    );
  }
}

class _PhotoActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;
  final VoidCallback onPressed;

  const _PhotoActionButton({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
