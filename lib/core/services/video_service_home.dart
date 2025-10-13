import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:mymink/core/services/video_service.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:mymink/core/services/my_video_cache_manager.dart';

class VideoServiceHome extends ChangeNotifier {
  VideoServiceHome() {
    _registry[this] = _CellState(); // register cell in global arbiter
  }

  String? videoUrl;

  static final MyVideoCacheManager _manager = MyVideoCacheManager();

  VideoPlayerController? videoPlayerController;
  ChewieController? chewieController;

  Timer? _muteIconTimer;

  bool _hasLoaded = false;
  bool isPlaying = false;
  bool showMuteIcon = false;
  bool _isDisposed = false;

  double _lastVisibility = 0.0;
  bool _shouldPlayAfterInit = false;
  bool _isInitializing = false;
  String? _currentUrl;

  // remember if we were playing when app went background
  bool _resumeOnForeground = false;

  // --- Instagram-like policy ---
  static const double _eligibility =
      0.95; // must be ≥ 95% visible to be eligible
  static const double _stickiness = 0.95; // keep current until it drops < 95%

  // ---- GLOBAL ARBITER STATE ----
  static final Map<VideoServiceHome, _CellState> _registry =
      <VideoServiceHome, _CellState>{};
  static VideoServiceHome? _current; // currently allowed to play

  // ===================================================================
  // Upload/cache helper (unchanged)
  // ===================================================================
  static Future<void> downloadVideoInCache(String url) async {
    final fileInfo = await _manager.getFileFromCache(url);
    if (fileInfo == null || !(await fileInfo.file.exists())) {
      await _manager.getSingleFile(url);
    }
  }

  // ===================================================================
  // Init / load
  // ===================================================================
  Future<void> loadVideo(String url) async {
    if (_isDisposed) return;
    if (_currentUrl == url && videoPlayerController != null) return;
    if (_isInitializing && _currentUrl == url) return;

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
      aspectRatio: c.value.aspectRatio,
    );

    await c.setLooping(true);
    await c.setVolume(MuteUnmute.isMuted ? 0 : 1);
    notifyListeners();

    // honor queued autoplay ONLY if we are the elected current cell
    if (_shouldPlayAfterInit) {
      _shouldPlayAfterInit = false;
      if (_current == this) {
        await c.play();
        isPlaying = true;
        notifyListeners();
      }
    }
  }

  // ===================================================================
  // Visibility + Election (Instagram policy)
  // ===================================================================
  void onVisibilityChanged(VisibilityInfo info) {
    if (_isDisposed) return;

    // Update our local basics
    _lastVisibility = info.visibleFraction;

    // Lazy-load once somewhat on screen
    if (!_hasLoaded && _lastVisibility > 0.20 && videoUrl != null) {
      _hasLoaded = true;
      unawaited(loadVideo(videoUrl!));
    }

    // Update the global registry with our current fraction + global top
    final st = _registry[this]!;
    st.fraction = _lastVisibility.clamp(0.0, 1.0);
    // visibleBounds is in global coordinates already
    final rect = info.visibleBounds;
    st.top = rect.top.isFinite ? rect.top : double.infinity;
    st.isOnScreen = !rect.isEmpty;

    _electAndApply(); // run the arbiter
  }

  // The global election: play the first visible-enough, stick until it drops below 95%
  static void _electAndApply() {
    // Filter to those on screen
    final entries = _registry.entries.where((e) => e.value.isOnScreen).toList();
    if (entries.isEmpty) {
      // pause any current if nothing on screen
      _current?._ensurePaused();
      _current = null;
      return;
    }

    // Which cells are ≥ 95% visible?
    final eligible =
        entries.where((e) => e.value.fraction >= _eligibility).toList();

    if (eligible.isEmpty) {
      // No one is fully eligible: pause current and stop
      _current?._ensurePaused();
      _current = null;
      return;
    }

    // Sort eligible by global top (the one that appears first on screen wins)
    eligible.sort((a, b) => a.value.top.compareTo(b.value.top));
    final VideoServiceHome winner = eligible.first.key;

    // If we already have a current:
    if (_current != null) {
      // If current is still ≥ 95% visible, KEEP it (stickiness)
      if (_registry[_current]!.fraction >= _stickiness &&
          _registry[_current]!.isOnScreen) {
        // Ensure current is actually playing; pause the others
        _current!._ensurePlaying();
        for (final e in _registry.keys) {
          if (e != _current) e._ensurePaused();
        }
        return;
      }
      // Otherwise, current dropped below 95% -> switch to the winner
      if (_current != winner) {
        _current!._ensurePaused();
        _current = winner;
        _current!._ensurePlaying();
        for (final e in _registry.keys) {
          if (e != _current) e._ensurePaused();
        }
        return;
      }
      // If winner == current but it’s <95% (rare due to prior branch), we still enforce play/pause
    }

    // No current or switching to first-eligible-by-top
    _current = winner;
    _current!._ensurePlaying();
    for (final e in _registry.keys) {
      if (e != _current) e._ensurePaused();
    }
  }

  // ===================================================================
  // Playback primitives
  // ===================================================================
  void _ensurePlaying() async {
    if (_isDisposed) return;
    final c = videoPlayerController;

    if (c == null || !c.value.isInitialized) {
      _shouldPlayAfterInit = true;
      if (!_hasLoaded && videoUrl != null) {
        _hasLoaded = true;
        unawaited(loadVideo(videoUrl!));
      }
      return;
    }

    if (!isPlaying) {
      await c.setVolume(MuteUnmute.isMuted ? 0 : 1);
      await c.play();
      isPlaying = true;
      notifyListeners();
    }
  }

  void _ensurePaused() {
    if (_isDisposed) return;
    final c = videoPlayerController;
    if (c != null && isPlaying) {
      c.pause();
      isPlaying = false;
      notifyListeners();
    }
  }

  // External taps (optional)
  void pauseVideo() {
    if (isPlaying) _resumeOnForeground = true;
    _ensurePaused();
    if (_current == this) _current = null;
  }

  void playVideo() {
    // external play means: try to become current NOW (if policy allows)
    // mark us as on-screen & eligible short-circuit (if a controller exists)
    final st = _registry[this]!;
    st.isOnScreen = true;
    st.fraction = 1.0;
    st.top = st.top; // unchanged
    _electAndApply();
  }

  void handleAppResumed() {
    if (_isDisposed) return;
    if (_resumeOnForeground) {
      _resumeOnForeground = false;
      // Resume only if still current and still eligible enough
      if (_current == this && _registry[this]!.fraction >= _eligibility) {
        _ensurePlaying();
      }
    } else {
      // Re-apply policy after resume
      _electAndApply();
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

  // ===================================================================
  // Cleanup
  // ===================================================================
  void disposeVideo() {
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

    if (_current == this) _current = null;

    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    // unregister from arbiter
    _registry.remove(this);
    // if we were current, clear and re-elect (so someone else can play)
    if (_current == this) {
      _current = null;
      _electAndApply();
    }
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

// Per-cell runtime state in the global arbiter
class _CellState {
  double fraction = 0.0; // visibleFraction
  double top = double.infinity; // global top of visibleBounds
  bool isOnScreen = false;
}
