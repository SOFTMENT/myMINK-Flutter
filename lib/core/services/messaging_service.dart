import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_service.dart';

class MessagingService {
  final FirebaseMessaging _messaging = FirebaseService().messaging;

  // ✅ Get the device token for FCM
  Future<String?> getDeviceToken() async {
    try {
      String? token = await _messaging.getToken();
      print('Device Token: $token');
      return token;
    } catch (e) {
      print('Get Device Token Error: ${e.toString()}');
      return null;
    }
  }
}
