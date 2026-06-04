import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/role_guard.dart';

class PhotosScreen extends StatefulWidget {
  final AuthService authService;

  const PhotosScreen({super.key, required this.authService});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  static const Color _ink = Color(0xFF334155);
  static const Color _mutedInk = Color(0xFF64748B);
  static const Color _peach = Color(0xFFFFE8D6);
  static const Color _mint = Color(0xFFDFF7EA);
  static const Color _sky = Color(0xFFDDF1FF);

  bool uploading = false;
  late final RoleGuardService roleGuardService;

  @override
  void initState() {
    super.initState();
    roleGuardService = RoleGuardService(authService: widget.authService);
  }

  Future<void> uploadPhoto(UserAccess access) async {
    if (!access.canEditContent) {
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

      await FirebaseFirestore.instance.collection('photos').add({
        'imageUrl': imageUrl,
        'title': 'Foto aus der Kita',
        'uploadedBy': uid,
        ...access.contentScopeFields(),
        'createdAt': Timestamp.now(),
      });

      debugPrint(
        'PhotosScreen: creating notification request for photo upload by uid=$uid',
      );

      final notificationRequest = await FirebaseFirestore.instance
          .collection('notificationRequests')
          .add({
            'type': 'photo_uploaded',
            'title': 'Neue Fotos verfügbar',
            'body': 'Es wurden neue Fotos in KitaConnect hochgeladen.',
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': uid,
            'status': 'pending',
          });

      debugPrint(
        'PhotosScreen: notification request created with id=${notificationRequest.id}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto hochgeladen – Benachrichtigung vorbereitet'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    }

    if (mounted) setState(() => uploading = false);
  }

  String getStringValue(QueryDocumentSnapshot doc, String key) {
    final data = doc.data() as Map<String, dynamic>;
    final value = data[key];
    if (value == null) return '';
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserAccess?>(
      future: roleGuardService.loadAccess(),
      builder: (context, accessSnapshot) {
        if (accessSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final access = accessSnapshot.data;
        if (access == null) return const AccessDeniedScreen();
        final canEdit = access.canEditContent;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Fotos'),
            actions: [
              if (canEdit)
                IconButton(
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
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: access
                .scopeCollection(
                  FirebaseFirestore.instance.collection('photos'),
                  createdByField: 'uploadedBy',
                )
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Fehler beim Laden der Fotos'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final photos = snapshot.data!.docs;

              if (photos.isEmpty) {
                return const Center(child: Text('Noch keine Fotos vorhanden.'));
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
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                      childAspectRatio: crossAxisCount == 1 ? 0.95 : 0.72,
                    ),
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      return _buildPhotoCard(context, photo, index, canEdit);
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPhotoCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> photo,
    int index,
    bool canEdit,
  ) {
    final imageUrl = getStringValue(photo, 'imageUrl');
    final title = getStringValue(photo, 'title');
    final caption = getStringValue(photo, 'caption');
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
                          title.isEmpty ? 'Foto aus der Kita' : title,
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
                        Expanded(
                          child: Text(
                            caption.isEmpty ? 'Keine Beschreibung' : caption,
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
                            if (canEdit)
                              _PhotoActionButton(
                                icon: Icons.edit_note_rounded,
                                label: 'Bearbeiten',
                                foreground: const Color(0xFF7C3AED),
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
                                          'Beschreibung bearbeiten',
                                        ),
                                        content: TextField(
                                          controller: descriptionController,
                                          maxLines: 4,
                                          decoration: const InputDecoration(
                                            hintText:
                                                'Beschreibung eingeben...',
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
                                                        descriptionController
                                                            .text
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
                                      'Download-Funktion wird als nächstes aktiviert',
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
