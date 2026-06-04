import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/role_guard.dart';

const Color _ink = Color(0xFF334155);
const Color _mutedInk = Color(0xFF64748B);
const Color _peach = Color(0xFFFFE8D6);
const Color _sky = Color(0xFFDDF1FF);
const Color _rose = Color(0xFFFFDCEB);
const Color _yellow = Color(0xFFFFF1A8);
const Color _purple = Color(0xFF7C3AED);
const Color _pink = Color(0xFFDB2777);
const Color _blue = Color(0xFF0284C7);

class MessagesScreen extends StatefulWidget {
  final AuthService authService;

  const MessagesScreen({super.key, required this.authService});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final messageController = TextEditingController();
  bool sending = false;
  late final RoleGuardService roleGuardService;

  @override
  void initState() {
    super.initState();
    roleGuardService = RoleGuardService(authService: widget.authService);
  }

  Future<void> sendMessage(UserAccess access) async {
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
            ...access.contentScopeFields(),
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

        return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Nachrichten',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: _ink),
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
        child: Column(
          children: [
            const SizedBox(height: 88),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _ConversationCard(
                title: 'Kita-Team & Eltern',
                preview: 'Direkter Austausch zwischen Eltern und Kita-Team.',
                time: 'Live',
                unreadCount: 1,
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: access
                    .scopeCollection(
                      FirebaseFirestore.instance.collection('messages'),
                      createdByField: 'senderId',
                    )
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
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
            _MessageInputBar(
              controller: messageController,
              sending: sending,
              onSend: () => sendMessage(access),
            ),
          ],
        ),
      ),
        );
      },
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final String title;
  final String preview;
  final String time;
  final int unreadCount;

  const _ConversationCard({
    required this.title,
    required this.preview,
    required this.time,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
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
      child: Stack(
        children: [
          const _DecorativeIcon(
            icon: Icons.auto_awesome_rounded,
            color: Color(0x337C3AED),
            size: 58,
            right: -14,
            top: -18,
          ),
          const _DecorativeIcon(
            icon: Icons.star_rounded,
            color: Color(0x33059F69),
            size: 24,
            left: 44,
            bottom: -2,
          ),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_rose, _yellow],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _pink.withValues(alpha: 0.16),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.forum_rounded, color: _pink, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: const TextStyle(
                            color: _mutedInk,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _mutedInk,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 28),
                  child: Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: const BoxDecoration(
                      color: _purple,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
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
    final bubbleGradient = isOwnMessage
        ? const [Color(0xFF8B5CF6), Color(0xFF38BDF8)]
        : const [Colors.white, _peach];
    final textColor = isOwnMessage ? Colors.white : _ink;
    final metaColor = isOwnMessage ? Colors.white70 : _mutedInk;
    final accent = isOwnMessage ? _purple : _pink;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isOwnMessage
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwnMessage) _BubbleAvatar(name: senderName, color: accent),
          if (!isOwnMessage) const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 340),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: bubbleGradient,
                ),
                borderRadius: BorderRadius.circular(24).copyWith(
                  bottomRight: isOwnMessage ? const Radius.circular(7) : null,
                  bottomLeft: isOwnMessage ? null : const Radius.circular(7),
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.16),
                    blurRadius: 18,
                    offset: const Offset(0, 9),
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
                        fontWeight: FontWeight.w900,
                        color: metaColor,
                      ),
                    ),
                  if (senderName.isNotEmpty) const SizedBox(height: 6),
                  Text(
                    text.isEmpty ? 'Nachricht' : text,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (time.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: metaColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isOwnMessage) const SizedBox(width: 8),
          if (isOwnMessage) _BubbleAvatar(name: senderName, color: _blue),
        ],
      ),
    );
  }
}

class _BubbleAvatar extends StatelessWidget {
  final String name;
  final Color color;

  const _BubbleAvatar({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _MessageInputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                enabled: !sending,
                decoration: InputDecoration(
                  hintText: 'Nachricht schreiben...',
                  prefixIcon: const Icon(
                    Icons.favorite_rounded,
                    color: _pink,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: _sky.withValues(alpha: 0.32),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: _purple, width: 1.4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 54,
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(21),
                  ),
                ),
                onPressed: sending ? null : onSend,
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
