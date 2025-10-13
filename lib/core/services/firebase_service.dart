import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class FirebaseService {
  // Singleton pattern for FirebaseService
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  /// **Log Errors to Firestore**
  static Future<void> logErrorToFirebase(String message) async {
    try {
      final deviceInfo = await _getDeviceInfo();
      final packageInfo = await PackageInfo.fromPlatform();

      await FirebaseFirestore.instance.collection("error_logs").add({
        "message": message,
        "timestamp": FieldValue.serverTimestamp(),
        "device": deviceInfo,
        "app_version": packageInfo.version,
      });
    } catch (e) {
      print("Failed to log error: $e");
    }
  }

  /// **Get Device Info for Debugging (Fixed)**
  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    final Map<String, dynamic> deviceData = {};

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceData.addAll({
          "model": androidInfo.model,
          "manufacturer": androidInfo.manufacturer,
          "android_version": androidInfo.version.release,
        });
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceData.addAll({
          "model": iosInfo.utsname.machine,
          "system_version": iosInfo.systemVersion,
        });
      }
    } catch (e) {
      print("Error fetching device info: $e");
    }

    return deviceData;
  }
}
