import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _local = FlutterLocalNotificationsPlugin();

  static Future<void> requestNotificationPermission() async {
    final messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notification permission granted');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('⚠️ Provisional permission granted');
    } else {
      print('❌ Notification permission denied');
    }
  }

  static Future<void> _showLocalNotification({
    required int id,
    String? title,
    String? body,
    String? payload,
  }) =>
      _local.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance',
            'High Importance Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: payload,
      );

  /// Must be a top‐level or static function
  static Future<void> _firebaseBackgroundHandler(RemoteMessage msg) async {
    await Firebase.initializeApp();
    final notif = msg.notification;
    if (notif != null) {
      await _showLocalNotification(
        id: notif.hashCode,
        title: notif.title,
        body: notif.body,
        payload: msg.data['someKey'],
      );
    }
  }

  static void registerMessageHandlers() {
    // Foreground
    FirebaseMessaging.onMessage.listen((msg) {
      final notif = msg.notification;
      if (notif != null) {
        _showLocalNotification(
          id: notif.hashCode,
          title: notif.title,
          body: notif.body,
          payload: msg.data['someKey'],
        );
      }
    });

    // App opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      // navigate or handle deep link
    });
  }

  /// Call once in main() after Firebase.initializeApp()
  static Future<void> init() async {
    // 1️⃣ Initialize flutter_local_notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (resp) {
        // handle tapped notification
      },
    );

    // 2️⃣ Create an Android channel (for >= Android 8.0)
    const channel = AndroidNotificationChannel(
      'high_importance',
      'High Importance Notifications',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3️⃣ Hook FCM background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // 4️⃣ Listen to token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      // send this new token to your backend / Firestore
    });
  }
}
