import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class MessagesScreen extends StatefulWidget {
  final AuthService authService;

  const MessagesScreen({super.key, required this.authService});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final messageController = TextEditingController();
  bool sending = false;

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || sending) return;

    final user = widget.authService.currentUser;
    if (user == null) {
      debugPrint('MessagesScreen: cannot send message without logged-in user');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bitte zuerst anmelden.')));
      }
      return;
    }

    setState(() => sending = true);

    try {
      final senderName = await loadSenderName(user.uid);

      debugPrint('MessagesScreen: saving message from uid=${user.uid}');
      final messageRef = await FirebaseFirestore.instance
          .collection('messages')
          .add({
            'text': text,
            'senderId': user.uid,
            'userId': user.uid,
            'senderName': senderName,
            'createdAt': FieldValue.serverTimestamp(),
            'childName': '',
            'status': 'sent',
          });

      debugPrint(
        'MessagesScreen: message saved with id=${messageRef.id}, '
        'creating notification request',
      );

      final notificationRequestRef = await FirebaseFirestore.instance
          .collection('notificationRequests')
          .add({
            'type': 'message_received',
            'title': 'Neue Nachricht',
            'body': buildNotificationBody(text),
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': user.uid,
            'status': 'pending',
            'relatedMessageId': messageRef.id,
          });

      debugPrint(
        'MessagesScreen: notification request created with '
        'id=${notificationRequestRef.id} for messageId=${messageRef.id}',
      );

      messageController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nachricht gesendet – Benachrichtigung vorbereitet'),
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('MessagesScreen: sendMessage failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => sending = false);
      }
    }
  }

  Future<String> loadSenderName(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = userDoc.data();
      final name = data?['name'];

      if (name is String && name.trim().isNotEmpty) {
        return name.trim();
      }
    } catch (error) {
      debugPrint('MessagesScreen: senderName lookup failed: $error');
    }

    return widget.authService.currentUser?.displayName?.trim().isNotEmpty ==
            true
        ? widget.authService.currentUser!.displayName!.trim()
        : 'KitaConnect Nutzer';
  }

  String buildNotificationBody(String text) {
    const maxLength = 120;
    final singleLine = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (singleLine.length <= maxLength) {
      return singleLine;
    }

    return '${singleLine.substring(0, maxLength - 1)}…';
  }

  String getStringValue(QueryDocumentSnapshot doc, String key) {
    final data = doc.data() as Map<String, dynamic>;
    final value = data[key];
    if (value == null) return '';
    return value.toString();
  }

  String formatMessageTime(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final createdAt = data['createdAt'];

    if (createdAt is! Timestamp) {
      return '';
    }

    final date = createdAt.toDate();
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = widget.authService.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      appBar: AppBar(title: const Text('Nachrichten')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFFDBEAFE), Color(0xFFFCE7F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.chat_bubble_rounded, color: Color(0xFF2563EB)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Direkter Austausch zwischen Eltern und Kita-Team.',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Fehler beim Laden der Nachrichten'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return const Center(child: Text('Noch keine Nachrichten'));
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final senderId = getStringValue(message, 'senderId');
                    final legacyUserId = getStringValue(message, 'userId');
                    final isOwnMessage =
                        currentUserId != null &&
                        (senderId == currentUserId ||
                            legacyUserId == currentUserId);

                    return _MessageBubble(
                      text: getStringValue(message, 'text'),
                      senderName: getStringValue(message, 'senderName'),
                      time: formatMessageTime(message),
                      isOwnMessage: isOwnMessage,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      minLines: 1,
                      maxLines: 4,
                      enabled: !sending,
                      decoration: InputDecoration(
                        hintText: 'Nachricht schreiben...',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: sending ? null : sendMessage,
                      child: sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final String senderName;
  final String time;
  final bool isOwnMessage;

  const _MessageBubble({
    required this.text,
    required this.senderName,
    required this.time,
    required this.isOwnMessage,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isOwnMessage ? const Color(0xFF2563EB) : Colors.white;
    final textColor = isOwnMessage ? Colors.white : const Color(0xFF1E293B);
    final metaColor = isOwnMessage ? Colors.white70 : const Color(0xFF64748B);

    return Align(
      alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(22).copyWith(
            bottomRight: isOwnMessage ? const Radius.circular(6) : null,
            bottomLeft: isOwnMessage ? null : const Radius.circular(6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (senderName.isNotEmpty)
              Text(
                senderName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: metaColor,
                ),
              ),
            if (senderName.isNotEmpty) const SizedBox(height: 5),
            Text(
              text.isEmpty ? 'Nachricht' : text,
              style: TextStyle(fontSize: 15, height: 1.35, color: textColor),
            ),
            if (time.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(time, style: TextStyle(fontSize: 11, color: metaColor)),
            ],
          ],
        ),
      ),
    );
  }
}
