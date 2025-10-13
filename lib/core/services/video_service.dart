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
  String? videoUrl;

  static final MyVideoCacheManager _manager = MyVideoCacheManager();

  VideoPlayerController? videoPlayerController;
  ChewieController? chewieController;

  Timer? _visibilityTimer;
  Timer? _muteIconTimer;

  bool _hasLoaded = false;
  bool isPlaying = false;
  bool showMuteIcon = false;
  bool _isDisposed = false;

  double _lastVisibility = 0.0;
  bool _shouldPlayAfterInit = false;
  bool _isInitializing = false;
  String? _currentUrl;

  // NEW: remember if we were playing when app went background
  bool _resumeOnForeground = false;

  static const double _playThreshold = 0.7;
  static const double _pauseThreshold = 0.3;

  static VideoService? currentlyPlaying;

  static Future<void> downloadVideoInCache(String url) async {
    final fileInfo = await _manager.getFileFromCache(url);
    if (fileInfo == null || !(await fileInfo.file.exists())) {
      await _manager.getSingleFile(url);
    }
    return;
  }

  Future<void> loadVideo(String url) async {
    if (_isDisposed) return;

    if (_currentUrl == url && videoPlayerController != null) {
      return;
    }

    if (_isInitializing && _currentUrl == url) {
      return;
    }

    _isInitializing = true;
    _currentUrl = url;

    try {
      final fileInfo = await _manager.getFileFromCache(url);
      VideoPlayerController controller;
      if (fileInfo != null && await fileInfo.file.exists()) {
        controller = VideoPlayerController.file(fileInfo.file);
      } else {
        controller = VideoPlayerController.networkUrl(Uri.parse(url));
      }

      if (_isDisposed) return;
      await _initController(controller);
    } catch (_) {
      if (_isDisposed) return;
      final fallback = VideoPlayerController.networkUrl(Uri.parse(url));
      await _initController(fallback);
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _initController(VideoPlayerController c) async {
    await c.initialize();
    if (_isDisposed) return;

    videoPlayerController?.dispose();
    chewieController?.dispose();

    videoPlayerController = c;
    chewieController = ChewieController(
      videoPlayerController: c,
      autoPlay: false,
      looping: true,
      showControls: false,
      allowMuting: false,
    );
    notifyListeners();

    if (_shouldPlayAfterInit || _lastVisibility >= _playThreshold) {
      _shouldPlayAfterInit = false;
      if (currentlyPlaying != null && currentlyPlaying != this) {
        currentlyPlaying!.pauseVideo();
      }
      c.setVolume(MuteUnmute.isMuted ? 0 : 1);
      await c.play();
      isPlaying = true;
      currentlyPlaying = this;
      notifyListeners();
    }
  }

  void onVisibilityChanged(VisibilityInfo info) {
    if (_isDisposed) return;

    _lastVisibility = info.visibleFraction;
    final v = _lastVisibility;

    if (!_hasLoaded && v > 0.2 && videoUrl != null) {
      _hasLoaded = true;
      unawaited(loadVideo(videoUrl!));
    }

    if (videoPlayerController == null) {
      _shouldPlayAfterInit = v >= _playThreshold;
      return;
    }

    if (v >= _playThreshold) {
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

    if (v <= _pauseThreshold) {
      _visibilityTimer?.cancel();
      _visibilityTimer = Timer(const Duration(milliseconds: 120), () {
        if (isPlaying &&
            videoPlayerController != null &&
            _lastVisibility <= _pauseThreshold) {
          videoPlayerController!.pause();
          isPlaying = false;
          if (currentlyPlaying == this) {
            currentlyPlaying = null;
          }
          notifyListeners();
        }
      });
    }
  }

  void pauseVideo() {
    // Remember intent so we can auto-resume when app returns
    if (isPlaying) _resumeOnForeground = true;

    if (videoPlayerController != null && isPlaying) {
      videoPlayerController!.pause();
      isPlaying = false;
      if (currentlyPlaying == this) currentlyPlaying = null;
      notifyListeners();
    }
  }

  void playVideo() {
    if (videoPlayerController != null && !isPlaying) {
      videoPlayerController!.setVolume(MuteUnmute.isMuted ? 0 : 1);
      videoPlayerController!.play();
      isPlaying = true;
      currentlyPlaying = this;
      notifyListeners();
    } else if (videoPlayerController == null && videoUrl != null) {
      _shouldPlayAfterInit = true;
      if (!_hasLoaded) {
        _hasLoaded = true;
        unawaited(loadVideo(videoUrl!));
      }
    }
  }

  // NEW: called on app resume by ReelItem
  void handleAppResumed() {
    // If we were playing before pause, and we're visible enough now, resume.
    if (_resumeOnForeground) {
      _resumeOnForeground = false;
      if (_lastVisibility >= _playThreshold) {
        playVideo();
      }
    } else {
      // Even if we weren't marked, if very visible, ensure play.
      if (_lastVisibility >= _playThreshold) {
        playVideo();
      }
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

  void disposeVideo() {
    _visibilityTimer?.cancel();
    _muteIconTimer?.cancel();

    try {
      videoPlayerController?.pause();
    } catch (_) {}

    videoPlayerController?.dispose();
    chewieController?.dispose();

    videoPlayerController = null;
    chewieController = null;

    isPlaying = false;
    _shouldPlayAfterInit = false;
    _hasLoaded = false;
    _isInitializing = false;
    _currentUrl = null;
    _resumeOnForeground = false;

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
