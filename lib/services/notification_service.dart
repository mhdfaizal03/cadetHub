import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ncc_cadet/models/notification_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Background handler must be top-level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message ${message.messageId}');
}

class NotificationService {
  final CollectionReference _db = FirebaseFirestore.instance.collection(
    'notifications',
  );

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> requestPermission() async {
    try {
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(alert: true, badge: true, sound: true);

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('User granted provisional permission');
      } else {
        debugPrint('User declined or has not accepted permission');
      }
    } catch (e) {
      debugPrint("Error requesting notification permission: $e");
    }
  }

  Future<void> initialize() async {
    try {
      // 1. Request Permission (Safe call)
      await requestPermission();

      // 2. Set Background Handler
      try {
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );
      } catch (e) {
        debugPrint("Error setting background handler: $e");
      }

      // 3. Initialize Local Notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings();

      final InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin,
          );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint("Notification Tapped: ${details.payload}");
        },
      );

      // Create Channel for Android
      if (!kIsWeb) {
        try {
          const AndroidNotificationChannel channel = AndroidNotificationChannel(
            'high_importance_channel', // id
            'High Importance Notifications', // title
            importance: Importance.max,
          );
          await _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.createNotificationChannel(channel);
        } catch (e) {
          debugPrint("Error creating Android channel: $e");
        }
      }

      // 4. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        try {
          debugPrint('Got a message whilst in the foreground!');
          RemoteNotification? notification = message.notification;
          AndroidNotification? android = message.notification?.android;

          if (notification != null && (android != null || kIsWeb)) {
            _flutterLocalNotificationsPlugin.show(
              notification.hashCode,
              notification.title,
              notification.body,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  'high_importance_channel',
                  'High Importance Notifications',
                  icon: '@mipmap/ic_launcher',
                  importance: Importance.max,
                  priority: Priority.high,
                ),
              ),
            );
          }
        } catch (e) {
          debugPrint("Error handling foreground message: $e");
        }
      });

      // 5. Get and Save Token
      await saveTokenToDatabase();

      // 6. Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((token) {
        saveTokenToDatabase(token);
      });
    } catch (e) {
      debugPrint("Error initializing NotificationService: $e");
    }
  }

  Future<void> saveTokenToDatabase([String? token]) async {
    try {
      String? fcmToken = token;
      if (fcmToken == null) {
        try {
          fcmToken = await _firebaseMessaging.getToken();
        } catch (e) {
          debugPrint("Error fetching FCM token: $e");
          return;
        }
      }

      User? user = FirebaseAuth.instance.currentUser;

      if (user != null && fcmToken != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': fcmToken});
        debugPrint("FCM Token Saved: $fcmToken");
      }
    } catch (e) {
      debugPrint("Error saving token to database: $e");
    }
  }

  // Send a notification (Database only for now, Cloud Function needed for actual push)
  Future<void> sendNotification(NotificationModel notification) async {
    await _db.add(notification.toMap());
  }

  // Get notifications for a cadet (Organization broadcast + Personal)
  Stream<QuerySnapshot> getNotifications(
    String organizationId,
    String cadetId,
  ) {
    return _db
        .where(
          Filter.or(
            Filter.and(
              Filter('type', isEqualTo: 'organization'),
              Filter('targetId', isEqualTo: organizationId),
            ),
            Filter.and(
              Filter('type', isEqualTo: 'cadet'),
              Filter('targetId', isEqualTo: cadetId),
            ),
          ),
        )
        // Note: Ordering by createdAt with OR queries typically requires composite index.
        // If query fails, we might need to sort client-side or modify query.
        // For now, let's try basic query or just organization notifications first if complex index is needed.
        // .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((e) {
          debugPrint('Error fetching notifications: $e');
          throw e;
        });
  }

  // Subscribe to a topic (e.g., 'organization_XYZ', 'organization_XYZ_year_1st Year')
  Future<void> subscribeToTopic(String topic) async {
    if (kIsWeb) {
      debugPrint("Web does not support topic subscription client-side.");
      return;
    }
    await _firebaseMessaging.subscribeToTopic(topic);
    debugPrint("Subscribed to topic: $topic");
  }

  // Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (kIsWeb) {
      return;
    }
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    debugPrint("Unsubscribed from topic: $topic");
  }

  // Send Push Notification via FCM Legacy API
  // NOTE: Ideally this should be done via Cloud Functions to keep Server Key secure.
  // For this client-side implementation, we need the Server Key.
  // Replace 'YOUR_SERVER_KEY' with your actual Firebase Cloud Messaging Server Key.
  static const String _serverKey = 'YOUR_SERVER_KEY_HERE';

  Future<void> sendPushNotification({
    required String title,
    required String body,
    String? topic, // e.g., 'organization_XYZ'
    String? token, // Specific device token
  }) async {
    if (_serverKey == 'YOUR_SERVER_KEY_HERE') {
      debugPrint(
        "FCM Server Key not configured. Push notification restricted.",
      );
      return;
    }

    if (topic == null && token == null) {
      debugPrint(
        "Error: Neither topic nor token provided for push notification.",
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode({
          'to': token ?? '/topics/$topic',
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
            'badge': 1,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
          'priority': 'high',
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'status': 'done',
            'screen': 'notifications', // Can be used for routing
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("Push notification sent successfully to ${token ?? topic}");
      } else {
        debugPrint(
          "Failed to send push notification: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      debugPrint("Error sending push notification: $e");
    }
  }
}
