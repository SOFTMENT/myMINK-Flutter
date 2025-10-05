class CallkitConfig {
  static String? _agoraAppId;

  static void initialize({required String agoraAppId}) {
    _agoraAppId = agoraAppId;
  }

  static String get agoraAppId {
    if (_agoraAppId == null) {
      throw Exception(
        "Agora App ID is not initialized. Call CallkitConfig.initialize first.",
      );
    }
    return _agoraAppId!;
  }
}
