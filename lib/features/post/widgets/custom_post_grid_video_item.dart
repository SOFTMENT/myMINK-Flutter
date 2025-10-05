import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:mymink/core/services/aws_uploader.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:mymink/core/constants/api_constants.dart';
import 'package:mymink/core/services/video_service.dart';
import 'package:mymink/features/post/data/models/post_model.dart';
import 'package:mymink/core/widgets/custom_image.dart';

/// Displays a video post using Chewie (render only).
/// - Square, BoxFit.cover
/// - Autoplay when > 50% visible
/// - ALWAYS muted (even after app resume)
class PostGridVideoItem extends StatefulWidget {
  final PostModel post;
  const PostGridVideoItem({Key? key, required this.post}) : super(key: key);

  @override
  _PostGridVideoItemState createState() => _PostGridVideoItemState();
}

class _PostGridVideoItemState extends State<PostGridVideoItem>
    with WidgetsBindingObserver {
  VideoService? _videoService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initService();
  }

  void _initService() {
    if (widget.post.postType != PostType.video.name ||
        widget.post.postVideo == null) return;

    _videoService = VideoService()
      ..videoUrl = ApiConstants.getFullVideoURL(widget.post.postVideo!);

    // Eager-load so the controller exists quickly
    _videoService!.loadVideo(_videoService!.videoUrl!).then((_) {
      final vc = _videoService?.videoPlayerController;
      if (!mounted || vc == null || !vc.value.isInitialized) return;

      // Always mute in search grid
      vc.setVolume(0);
      // You were auto-playing; keep that behavior
      vc.play();
      _videoService!.isPlaying = true;

      setState(() {}); // reveal Chewie once ready
    });
  }

  @override
  void didUpdateWidget(covariant PostGridVideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.postVideo != oldWidget.post.postVideo) {
      _disposeService();
      _initService();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || _videoService == null) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _videoService?.pauseVideo();
    } else if (state == AppLifecycleState.resumed) {
      // Let the service decide based on last visibleFraction, then enforce mute
      _videoService?.handleAppResumed();
      _forceMute();

      // Re-fire visibility so on-screen tiles recompute fraction
      WidgetsBinding.instance.addPostFrameCallback((_) {
        VisibilityDetectorController.instance.notifyNow();
        _forceMute();
      });
    }
  }

  void _forceMute() {
    try {
      _videoService?.videoPlayerController?.setVolume(0);
    } catch (_) {}
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    // Keep service state in sync so handleAppResumed() works
    _videoService?.onVisibilityChanged(info);

    final vc = _videoService?.videoPlayerController;
    if (vc == null) return;

    if (info.visibleFraction > 0.5) {
      // Play and force mute
      if (!vc.value.isPlaying) {
        _forceMute();
        vc.play();
        _videoService?.isPlaying = true;
      } else {
        _forceMute();
      }
    } else {
      if (vc.value.isPlaying) {
        vc.pause();
        _videoService?.isPlaying = false;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeService();
    super.dispose();
  }

  void _disposeService() {
    try {
      _videoService?.disposeVideo();
      _videoService?.dispose();
    } catch (_) {}
    _videoService = null;
  }

  @override
  Widget build(BuildContext context) {
    final chewie = _videoService?.chewieController;

    return VisibilityDetector(
      key: Key('post-grid-video-${widget.post.postID}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: AspectRatio(
        aspectRatio: 1.0, // Force square container
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: GestureDetector(
            onTap: () {
              // Keep your tap behavior, but enforce mute in grid
              _videoService?.toggleMute();
              _forceMute();
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Thumbnail always visible behind
                CustomImage(
                  imageKey: widget.post.videoImage,
                  width: 150,
                  height: 150,
                ),

                // Show video when controller is ready
                if (chewie != null)
                  AnimatedOpacity(
                    opacity: chewie.videoPlayerController.value.isInitialized
                        ? 1.0
                        : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: chewie.videoPlayerController.value.size.width,
                        height: chewie.videoPlayerController.value.size.height,
                        child: Chewie(controller: chewie),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
