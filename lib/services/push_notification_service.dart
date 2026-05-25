import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    if (kIsWeb) return;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground push received: ${message.messageId}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Push opened: ${message.data}');
    });
  }

  Future<void> registerCurrentDevice({String? role}) async {
    if (kIsWeb) return;

    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      final tokenData = <String, dynamic>{
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastFcmTokenUpdatedAt': DateTime.now().toIso8601String(),
      };
      if (role != null) tokenData['role'] = role;

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(tokenData, SetOptions(merge: true));

      _messaging.onTokenRefresh.listen((newToken) async {
        final refreshData = <String, dynamic>{
          'fcmTokens': FieldValue.arrayUnion([newToken]),
          'lastFcmTokenUpdatedAt': DateTime.now().toIso8601String(),
        };
        if (role != null) refreshData['role'] = role;

        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(refreshData, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('Failed to register FCM token: $e');
    }
  }

  Future<void> unregisterCurrentDevice() async {
    if (kIsWeb) return;

    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      await _firestore.collection('users').doc(firebaseUser.uid).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
        'lastFcmTokenUpdatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Failed to unregister FCM token: $e');
    }
  }
}
