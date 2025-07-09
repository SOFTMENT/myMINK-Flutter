import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/services/aws_uploader.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:mymink/core/constants/api_constants.dart';
import 'package:mymink/core/services/video_service.dart';
import 'package:mymink/features/post/data/models/post_model.dart';
import 'package:mymink/core/widgets/custom_image.dart';

/// Displays a video post using Chewie.
/// Each video is forced into a square, uses BoxFit.cover,
/// auto-plays when at least 50% visible, and is muted by default.
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
    loadVideo();
  }

  void loadVideo() {
    if (widget.post.postType == PostType.video.name &&
        widget.post.postVideo != null) {
      _videoService = VideoService()
        ..videoUrl = ApiConstants.getFullVideoURL(widget.post.postVideo!);

      _videoService!.loadVideo(_videoService!.videoUrl!).then((_) {
        final c = _videoService!.videoPlayerController;
        if (c != null && c.value.isInitialized) {
          c.setVolume(0); // mute this instance only
          c.play(); // start playing
          _videoService!.isPlaying = true;
          // no need to set MuteUnmute.isMuted
          setState(() {});
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant PostGridVideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.postVideo != oldWidget.post.postVideo) {
      // Dispose of the current video service before re-initializing.
      _videoService?.disposeVideo();

      _videoService = null;
      loadVideo();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (widget.post.postType == PostType.video.name && _videoService != null) {
      if (state == AppLifecycleState.paused) {
        _videoService?.pauseVideo();
      } else if (state == AppLifecycleState.resumed) {
        if (ModalRoute.of(context)?.isCurrent == true &&
            VideoService.currentlyPlaying == _videoService) {
          _videoService?.playVideo();
          _videoService?.isPlaying = true;
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoService?.disposeVideo();

    _videoService = null;
    super.dispose();
  }

  void _handleVisibility(VisibilityInfo info) {
    // If more than 50% is visible, play; otherwise, pause.
    if (info.visibleFraction > 0.5) {
      _videoService?.chewieController?.play();
    } else {
      _videoService?.chewieController?.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('post-grid-video-${widget.post.postID}'),
      onVisibilityChanged: (info) => _handleVisibility(info),
      child: AspectRatio(
        aspectRatio: 1.0, // Force square container
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: GestureDetector(
            onTap: () {
              _videoService?.toggleMute();
              _videoService?.chewieController?.videoPlayerController
                  .setVolume(0);
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Thumbnail always visible in background
                CustomImage(
                  imageKey: widget.post.videoImage,
                  width: 150,
                  height: 150,
                ),

                // Fade-in video when initialized
                if (_videoService?.chewieController != null)
                  AnimatedOpacity(
                    opacity: _videoService!.chewieController!
                            .videoPlayerController.value.isInitialized
                        ? 1.0
                        : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoService!.chewieController!
                            .videoPlayerController.value.size.width,
                        height: _videoService!.chewieController!
                            .videoPlayerController.value.size.height,
                        child: Chewie(
                          controller: _videoService!.chewieController!,
                        ),
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
