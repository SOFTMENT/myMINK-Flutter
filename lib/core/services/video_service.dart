// video_service.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:mymink/core/services/my_video_cache_manager.dart';

class MuteUnmute {
  static bool isMuted = false;
}

class VideoService extends ChangeNotifier {
  /// Set by PostItem; no load until visibility triggers
  String? videoUrl;

  final MyVideoCacheManager _manager = MyVideoCacheManager();

  VideoPlayerController? videoPlayerController;
  ChewieController? chewieController;

  Timer? _visibilityTimer;
  Timer? _muteIconTimer;

  bool _hasLoaded = false;
  bool isPlaying = false;
  bool showMuteIcon = false;
  bool _isDisposed = false;

  static VideoService? currentlyPlaying;

  /// Load & buffer video once triggered
  Future<void> loadVideo(String url) async {
    try {
      disposeVideo();
      final fileInfo = await _manager.getFileFromCache(url);
      VideoPlayerController controller;
      if (fileInfo != null && await fileInfo.file.exists()) {
        controller = await VideoPlayerController.file(fileInfo.file);
      } else {
        controller = await VideoPlayerController.networkUrl(Uri.parse(url));
        // cache in background
        _manager.getSingleFile(url);
      }
      if (_isDisposed) return;
      await _initController(controller);
      print(url);
    } catch (_) {
      // fallback to network-only
      final controller = await VideoPlayerController.networkUrl(Uri.parse(url));
      await _initController(controller);
    }
  }

  downloadVideoInCache(String url) async {
    final fileInfo = await _manager.getFileFromCache(url);

    if (fileInfo == null || await fileInfo.file.exists()) {
      _manager.getSingleFile(url);
    }
  }

  Future<void> _initController(VideoPlayerController c) async {
    await c.initialize();
    if (_isDisposed) return;
    videoPlayerController = c;
    chewieController = ChewieController(
      videoPlayerController: c,
      autoPlay: false,
      looping: true,
      showControls: false,
      allowMuting: false,
    );
    notifyListeners();
  }

  /// Handles visibility for preload, play, and pause
  void onVisibilityChanged(VisibilityInfo info) {
    final v = info.visibleFraction;

    // PRELOAD at ~20% visibility
    if (!_hasLoaded && v > 0.2 && videoUrl != null) {
      _hasLoaded = true;
      loadVideo(videoUrl!); // buffers but does not play
    }

    if (videoPlayerController == null) return;

    // PLAY immediately at >60%
    if (v > 0.6) {
      _visibilityTimer?.cancel();
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
      return;
    }

    // PAUSE with debounce when visibility drops ≤60%
    _visibilityTimer?.cancel();
    _visibilityTimer = Timer(const Duration(milliseconds: 200), () {
      if (isPlaying && info.visibleFraction <= 0.6) {
        videoPlayerController!.pause();
        isPlaying = false;
        if (currentlyPlaying == this) {
          currentlyPlaying = null;
        }
        notifyListeners();
      }
    });
  }

  /// Pause playback
  void pauseVideo() {
    if (videoPlayerController != null && isPlaying) {
      videoPlayerController!.pause();
      isPlaying = false;
      notifyListeners();
    }
  }

  /// Start playback
  void playVideo() {
    if (videoPlayerController != null && !isPlaying) {
      videoPlayerController!.setVolume(MuteUnmute.isMuted ? 0 : 1);
      videoPlayerController!.play();
      isPlaying = true;
      notifyListeners();
    }
  }

  /// Toggle mute + show icon
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

  /// Dispose controllers & timers
  void disposeVideo() {
    _visibilityTimer?.cancel();
    _muteIconTimer?.cancel();
    videoPlayerController?.pause();
    videoPlayerController?.dispose();
    chewieController?.dispose();
    videoPlayerController = null;
    chewieController = null;
    if (currentlyPlaying == this) {
      currentlyPlaying = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    disposeVideo();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}
