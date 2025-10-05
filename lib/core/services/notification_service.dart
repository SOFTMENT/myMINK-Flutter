import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:mymink/features/videocall/data/services/callkit_service.dart';

class NotificationService {
  static final _local = FlutterLocalNotificationsPlugin();

  static Future<void> requestNotificationPermission() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 👇 (For Android 14+ full screen call intent permission)
    await CallKitService.requestFullIntentPermission();
  }

  static Future<void> initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings iosSettings =
        const DarwinInitializationSettings();

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _local.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // handle payload if needed
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
  }

  static Future<void> showLocalNotification({
    required int id,
    String? title,
    String? body,
    String? payload,
  }) async {
    print(title);
    print(body);
    print(payload);

    await _local.show(
      id,
      title ?? 'No Title',
      body ?? 'No Body',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'ticker',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  /// Must be a top‐level or static function
  static Future<void> _firebaseBackgroundHandler(RemoteMessage msg) async {
    await Firebase.initializeApp();
    final notif = msg.notification;
    if (notif != null) {
      await showLocalNotification(
        id: notif.hashCode,
        title: notif.title,
        body: notif.body,
        payload: msg.data['someKey'],
      );
    }
  }

  static void registerMessageHandlers() {
    // App opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      // navigate or handle deep link
    });
  }

  /// Call once in main() after Firebase.initializeApp()
  static Future<void> init() async {
    await initializeNotifications();

    // 3️⃣ Hook FCM background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // 4️⃣ Listen to token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      // send this new token to your backend / Firestore
    });

    FirebaseMessaging.onMessage.listen((message) {
      final data = message.data;

      if (data['notificationtype'] == 'incoming_call') {
        showIncomingCall(data);
      } else {
        final notif = message.notification;
        if (notif != null) {
          showLocalNotification(
            id: notif.hashCode,
            title: notif.title,
            body: notif.body,
          );
        }
      }
    });
  }

  @pragma('vm:entry-point')
  Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await Firebase.initializeApp();
    final data = message.data;

    showIncomingCall(data);
  }

  static showIncomingCall(Map<String, dynamic> data) {
    final callerName = data['nameCaller'] ?? "Unknown";
    final callerId = data['id'] ?? "123";
    final agoraToken = data['agoraToken'] ?? "123";
    final channelName = data['channelName'] ?? 'channel';

    if (data['notificationtype'] == 'incoming_call') {
      CallKitService.showIncomingCall(
          callerName: callerName,
          callerId: callerId,
          token: agoraToken,
          channelName: channelName);
    }
  }

  static Future<void> sendCallNotification({
    required String fcmToken,
    required String agoraToken,
    required String channelName,
    required String callerName,
    required String callId,
  }) async {
    try {
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('sendUnifiedNotification');

      final response = await callable.call({
        'fcmToken': fcmToken,
        'agoraToken': agoraToken,
        'channelName': channelName,
        'callerName': callerName,
        'callId': callId,
      });

      print('✅ Notification sent: ${response.data}');
    } on FirebaseFunctionsException catch (e) {
      print('❌ FirebaseFunctionsException: ${e.message}');
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  static Future<void> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
  }) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('sendUnifiedNotification');

      final result = await callable.call({
        'fcmToken': fcmToken,
        'title': title,
        'body': body,
      });

      print('✅ Notification sent successfully: ${result.data}');
    } on FirebaseFunctionsException catch (e) {
      print('❌ FirebaseFunctionsException: ${e.code} - ${e.message}');
    } catch (e) {
      print('❌ Error sending push notification: $e');
    }
  }
}
