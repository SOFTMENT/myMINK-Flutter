// lib/src/callkit_initializer.dart

import 'package:flutter/material.dart';
import './call_kit_config.dart';
import './callkit_service.dart';

class CallkitInitializer {
  static void initialize({
    required String agoraAppId,
    required GlobalKey<NavigatorState> navigatorKey,
  }) {
    CallkitConfig.initialize(agoraAppId: agoraAppId);
    CallKitService.init(navigatorKey);
  }
}
