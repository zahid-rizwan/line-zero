import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FirebaseService.initialize();
  final notification = message.notification;
  if (notification != null) {
    NotificationService.instance.showSystemNotification(
      title: notification.title ?? 'Queue Update',
      body: notification.body ?? '',
      speakVoice: true,
    );
  }
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FlutterTts _flutterTts = FlutterTts();
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  static const String channelId = 'qtoken_notifications_v2';

  Future<void> initialize() async {
    // Initialize TTS Hindi settings
    try {
      await _flutterTts.setLanguage("hi-IN");
      await _flutterTts.setSpeechRate(0.46); // Natural clear Hindi voice speed
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      debugPrint('TTS Initialization notice: $e');
    }

    // 1. Initialize Flutter Local Notifications for Android system pop-up alerts
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification tapped: ${details.payload}');
        },
      );

      // Create High Priority Android Notification Channel v2
      const androidChannel = AndroidNotificationChannel(
        channelId,
        'Queue Updates',
        description: 'Real-time notifications for token queue position updates.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(androidChannel);
        await androidPlugin.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('Local notifications init notice: $e');
    }

    // 2. Initialize Firebase Messaging (if initialized)
    if (FirebaseService.isInitialized) {
      try {
        // Always register top-level background & killed app handler
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        final messaging = FirebaseMessaging.instance;
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          _fcmToken = await messaging.getToken();
          debugPrint('FCM Device Token: $_fcmToken');

          // Listen to Foreground Push Messages
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
            final notification = message.notification;
            if (notification != null) {
              final title = notification.title ?? 'Queue Update';
              final body = notification.body ?? '';
              showSystemNotification(title: title, body: body);
            }
          });
        }
      } catch (e) {
        debugPrint('FCM Messaging init notice: $e');
      }
    }
  }

  /// Syncs current device FCM token to Firestore user document
  Future<void> syncFcmTokenToFirestore(String userId) async {
    if (!FirebaseService.isInitialized) return;
    try {
      final token = _fcmToken ?? await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        _fcmToken = token;
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
        debugPrint('FCM Token successfully synced to Firestore for user: $userId');
      }
    } catch (e) {
      debugPrint('syncFcmTokenToFirestore error: $e');
    }
  }

  /// Explicitly request Android notification permission
  Future<bool?> requestNotificationsPermission() async {
    try {
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        debugPrint('Android Notification Permission Result: $granted');
        return granted;
      }
    } catch (e) {
      debugPrint('requestNotificationsPermission error: $e');
    }
    return true;
  }

  /// Speak a clear Text-To-Speech voice announcement out loud in HINDI
  Future<void> speakHindiVoiceAnnouncement(String text) async {
    try {
      await _flutterTts.stop();
      await _flutterTts.setLanguage("hi-IN");
      await _flutterTts.setSpeechRate(0.46);
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Hindi Voice announcement error: $e');
    }
  }

  /// Show a real System Heads-Up Notification on the Android device status bar and speak voice announcement in Hindi
  Future<void> showSystemNotification({
    required String title,
    required String body,
    String? hindiVoiceText,
    int? id,
    bool speakVoice = true,
  }) async {
    try {
      final notificationId = id ?? (Random().nextInt(100000) + 1);

      final androidDetails = AndroidNotificationDetails(
        channelId,
        'Queue Updates',
        channelDescription: 'Real-time notifications for token queue position updates.',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        icon: '@mipmap/ic_launcher',
        ticker: title,
        audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
      );

      final details = NotificationDetails(android: androidDetails);
      await _localNotifications.show(notificationId, title, body, details);

      if (speakVoice) {
        final speech = hindiVoiceText ?? body;
        if (speech.isNotEmpty) {
          await speakHindiVoiceAnnouncement(speech);
        }
      }
    } catch (e) {
      debugPrint('showSystemNotification error: $e');
    }
  }
}
