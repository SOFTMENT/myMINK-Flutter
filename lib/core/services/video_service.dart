import 'dart:async';

import 'package:chewie/chewie.dart';

import 'package:flutter/material.dart';
import 'package:mymink/core/services/my_video_cache_manager.dart';
import 'package:mymink/core/services/player_pool.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class MuteUnmute {
  static bool isMuted = false;
}

class VideoService extends ChangeNotifier {
  MyVideoCacheManager manager = MyVideoCacheManager();
  VideoPlayerController? videoPlayerController;
  ChewieController? chewieController;
  Timer? _muteIconTimer;
  Timer? _visibilityTimer;
  String? cachedFilePath;
  bool isPlaying = false;
  bool showMuteIcon = false;

  static VideoService? currentlyPlaying;
  VideoPlayerPool playerPool = VideoPlayerPool();

  Future<void> loadVideo(String videoURL) async {
    try {
      disposeVideo();
      final fileInfo = await manager.getFileFromCache(videoURL);
      if (fileInfo != null && await fileInfo.file.exists()) {
        await _playVideo(await playerPool.getControllerFromFile(fileInfo.file));
      } else {
        await _playVideo(await playerPool.getControllerFromNetwork(videoURL));
        _cacheVideo(videoURL);
      }
    } catch (e, stackTrace) {
      await _tryFallbackPlayer(videoURL);
    }
  }

  Future<void> _playVideo(VideoPlayerController controller) async {
    videoPlayerController = controller;
    chewieController = ChewieController(
      videoPlayerController: videoPlayerController!,
      autoPlay: false,
      looping: true,
      showControls: false,
      allowMuting: false,
    );
    notifyListeners();
  }

  Future<void> _tryFallbackPlayer(String videoURL) async {
    try {
      videoPlayerController =
          await playerPool.getControllerFromNetwork(videoURL);
      chewieController = ChewieController(
        videoPlayerController: videoPlayerController!,
        autoPlay: false,
        looping: true,
        showControls: false,
        allowMuting: false,
      );
      notifyListeners();
    } catch (e) {
      notifyListeners();
    }
  }

  void _cacheVideo(String videoURL) {
    try {
      manager.getSingleFile(videoURL).then((file) {
        cachedFilePath = file.path;
      });
    } catch (_) {}
  }

  void pauseVideo() {
    if (videoPlayerController != null && isPlaying) {
      videoPlayerController!.pause();
      isPlaying = false;
      notifyListeners();
    }
  }

  void playVideo() {
    if (videoPlayerController != null && !isPlaying) {
      videoPlayerController!.play();
      isPlaying = true;
      notifyListeners();
    }
  }

  void toggleMute() {
    if (videoPlayerController == null) return;
    MuteUnmute.isMuted = !MuteUnmute.isMuted;
    videoPlayerController!.setVolume(MuteUnmute.isMuted ? 0 : 1);
    showMuteIcon = true;
    notifyListeners();
    _muteIconTimer?.cancel();
    _muteIconTimer = Timer(const Duration(milliseconds: 1500), () {
      showMuteIcon = false;
      notifyListeners();
    });
  }

  void onVisibilityChanged(VisibilityInfo info) {
    if (videoPlayerController == null) return;
    _visibilityTimer?.cancel();
    _visibilityTimer = Timer(const Duration(milliseconds: 200), () {
      if (info.visibleFraction > 0.60) {
        if (!isPlaying) {
          if (currentlyPlaying != null && currentlyPlaying != this) {
            currentlyPlaying!.pauseVideo();
          }
          videoPlayerController!.setVolume(MuteUnmute.isMuted ? 0 : 1);
          videoPlayerController!.play();
          isPlaying = true;
          currentlyPlaying = this;
          notifyListeners();
        }
      } else if (info.visibleFraction <= 0.70 && isPlaying) {
        videoPlayerController!.pause();
        isPlaying = false;
        if (currentlyPlaying == this) {
          currentlyPlaying = null;
        }
        notifyListeners();
      }
    });
  }

  void disposeVideo() {
    _muteIconTimer?.cancel();
    _visibilityTimer?.cancel();
    videoPlayerController?.pause();
    videoPlayerController = null;
    chewieController?.dispose();
    chewieController = null;
    if (currentlyPlaying == this) {
      currentlyPlaying = null;
    }
    notifyListeners();
  }
}
