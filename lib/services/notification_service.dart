import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService({
    FirebaseMessaging? firebaseMessaging,
    FirebaseFirestore? firestore,
  }) : _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _firebaseMessaging;
  final FirebaseFirestore _firestore;

  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _initializedUserId;
  Future<void>? _initialization;

  static const _webVapidKey = String.fromEnvironment(
    'FIREBASE_MESSAGING_VAPID_KEY',
  );

  Future<void> initializeForUser(String uid) async {
    debugPrint('NotificationService: initializeForUser called for uid=$uid');

    if (_initializedUserId == uid) {
      debugPrint(
        'NotificationService: already initialized for uid=$uid, skipping',
      );
      final initialization = _initialization;
      if (initialization != null) {
        return initialization;
      }
      return;
    }

    _initializedUserId = uid;
    debugPrint('NotificationService: starting new initialization for uid=$uid');
    final initialization = _initializeForUser(uid);
    _initialization = initialization;
    return initialization;
  }

  Future<void> _initializeForUser(String uid) async {
    debugPrint('NotificationService: _initializeForUser started for uid=$uid');

    if (kIsWeb && _webVapidKey.isEmpty) {
      debugPrint(
        'NotificationService: no web VAPID key configured. '
        'Pass --dart-define=FIREBASE_MESSAGING_VAPID_KEY=... to receive '
        'web FCM tokens.',
      );
    }

    NotificationSettings? settings;
    try {
      debugPrint('NotificationService: requestPermission starting');
      settings = await _firebaseMessaging.requestPermission();
      debugPrint(
        'NotificationService: permission status=${settings.authorizationStatus}',
      );
      debugPrint('NotificationService: requestPermission completed');
    } catch (error, stackTrace) {
      debugPrint('NotificationService: requestPermission failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    try {
      debugPrint(
        'NotificationService: getToken starting, '
        'hasWebVapidKey=${!kIsWeb || _webVapidKey.isNotEmpty}',
      );
      final token = await _firebaseMessaging.getToken(
        vapidKey: kIsWeb && _webVapidKey.isNotEmpty ? _webVapidKey : null,
      );
      debugPrint('NotificationService: FCM token=$token');
      debugPrint('NotificationService: getToken completed');

      if (token != null) {
        await _saveToken(uid, token);
      }
    } catch (error, stackTrace) {
      debugPrint('NotificationService: getToken failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    if (settings == null) {
      debugPrint('NotificationService: continuing without permission result');
    }

    await _foregroundMessageSubscription?.cancel();
    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((
      message,
    ) {
      debugPrint(
        'NotificationService: foreground message received '
        'id=${message.messageId}, title=${message.notification?.title}',
      );
    });

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _firebaseMessaging.onTokenRefresh.listen((
      refreshedToken,
    ) async {
      debugPrint('NotificationService: refreshed FCM token=$refreshedToken');
      try {
        await _saveToken(uid, refreshedToken);
      } catch (error, stackTrace) {
        debugPrint('NotificationService: refreshed token save failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    });
  }

  Future<void> _saveToken(String uid, String token) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .doc(token)
        .set({
          'token': token,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'platform': defaultTargetPlatform.name,
        }, SetOptions(merge: true));

    debugPrint('NotificationService: token saved successfully');
  }
}
