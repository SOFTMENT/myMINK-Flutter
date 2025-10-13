import 'dart:io';

import 'package:video_player/video_player.dart';

class VideoPlayerPool {
  final List<VideoPlayerController> _controllers = [];
  final int maxControllers = 6;

  Future<VideoPlayerController> getControllerFromFile(File file) async {
    if (_controllers.length >= maxControllers) {
      _controllers.first.dispose();
      _controllers.removeAt(0);
    }
    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    _controllers.add(controller);
    return controller;
  }

  Future<VideoPlayerController> getControllerFromNetwork(String url) async {
    if (_controllers.length >= maxControllers) {
      _controllers.first.dispose();
      _controllers.removeAt(0);
    }
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await controller.initialize();
    _controllers.add(controller);
    return controller;
  }

  void disposeAll() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();
  }
}
