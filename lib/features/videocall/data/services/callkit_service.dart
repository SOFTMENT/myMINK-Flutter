import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:mymink/features/videocall/pages/video_call_page.dart';

class CallKitService {
  static Future<void> requestFullIntentPermission() async {
    await FlutterCallkitIncoming.requestFullIntentPermission();
  }

  static void init(GlobalKey<NavigatorState> navigatorKey) {
    FlutterCallkitIncoming.onEvent.listen((event) {
      print("📞 Event received: ${event?.event}");
      print("📦 Event data: ${event?.body}");

      final data = event?.body ?? {};
      final extra = data['extra'] ?? {};

      final token = extra['token'];
      final channelName = extra['channelName'];

      switch (event?.event) {
        case Event.actionCallAccept:
          print("✅ Call accepted. token: $token, channelName: $channelName");

          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => VideoCallPage(
                channelName: channelName,
                token: token,
                isCaller: false,
              ),
            ),
          );
          break;

        case Event.actionCallDecline:
          print("❌ Call declined");
          break;

        case Event.actionCallEnded:
        case Event.actionCallTimeout:
          print("🕓 Call ended or timed out");
          break;

        default:
          print("ℹ️ Unknown event: ${event?.event}");
          break;
      }
    });
  }

  static Future<void> showIncomingCall({
    required String callerName,
    required String callerId,
    required String token,
    required String channelName,
  }) async {
    final params = CallKitParams(
      id: callerId,
      nameCaller: callerName,
      handle: callerId,
      type: 1,
      textAccept: 'Accept',
      textDecline: 'Decline',
      missedCallNotification: const NotificationParams(
        showNotification: true,
        subtitle: 'Missed call',
        callbackText: 'Call back',
      ),
      callingNotification: const NotificationParams(
        showNotification: true,
        subtitle: 'Calling...',
        callbackText: 'Hang Up',
      ),
      android: const AndroidParams(
        isCustomNotification: true,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        actionColor: '#4CAF50',
        incomingCallNotificationChannelName: 'Incoming Call',
      ),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        handleType: 'generic',
        supportsVideo: true,
        ringtonePath: 'system_ringtone_default',
      ),
      extra: {"token": token, "channelName": channelName},
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }
}
