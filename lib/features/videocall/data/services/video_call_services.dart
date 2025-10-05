import 'package:cloud_functions/cloud_functions.dart';
import 'package:mymink/core/services/firebase_service.dart';

class VideoCallService {
  static String channelName = '';
  static String? agoraToken;

  static Future<void> initAgoraToken() async {
    if (FirebaseService().auth.currentUser == null) return;

    channelName = FirebaseService().auth.currentUser!.uid;
    try {
      agoraToken = await generateAgoraToken(channelName: channelName);
    } catch (e) {
      print('Failed to fetch Agora token: $e');
    }
  }

  static Future<String?> generateAgoraToken({
    required String channelName,
  }) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('generateAgoraToken');
      final result = await callable.call({'channelName': channelName});
      final data = result.data;
      if (data is Map<String, dynamic> && data['token'] is String) {
        return data['token'] as String;
      } else if (data is String) {
        return data;
      }
      return null;
    } catch (e) {
      // you could log e here if you want
      return null;
    }
  }
}
