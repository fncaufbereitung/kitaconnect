import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';

class PhotosScreen extends StatefulWidget {
  final AuthService authService;

  const PhotosScreen({super.key, required this.authService});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  bool uploading = false;

  Future<void> uploadPhoto() async {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fotos'),
        actions: [
          IconButton(
            icon: uploading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_a_photo),
            onPressed: uploading ? null : uploadPhoto,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('photos')
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

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              final imageUrl = getStringValue(photo, 'imageUrl');
              final title = getStringValue(photo, 'title');

              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: imageUrl.isEmpty
                          ? Container(
                              color: const Color(0xFFE2E8F0),
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 42,
                                color: Color(0xFF64748B),
                              ),
                            )
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFFE2E8F0),
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 42,
                                    color: Color(0xFF64748B),
                                  ),
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.isEmpty ? 'Foto aus der Kita' : title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            getStringValue(photo, 'caption').isEmpty
                                ? 'Keine Beschreibung'
                                : getStringValue(photo, 'caption'),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),

                          const SizedBox(height: 8),

                          TextButton.icon(
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
                                        hintText: 'Beschreibung eingeben...',
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
                                                'caption': descriptionController
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
                            icon: const Icon(Icons.edit_note),
                            label: const Text('Beschreibung hinzufügen'),
                          ),

                          TextButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Download-Funktion wird als nächstes aktiviert',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.download),
                            label: const Text('Download'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
