import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:go_router/go_router.dart';

import 'package:mymink/core/constants/api_constants.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/services/aws_uploader.dart';
import 'package:mymink/core/utils/time_ago_extension.dart';
import 'package:mymink/core/widgets/custom_icon_button.dart';
import 'package:mymink/core/widgets/custom_image.dart';

import 'package:mymink/features/onboarding/data/models/user_model.dart';

import 'package:mymink/features/post/data/models/post_model.dart';
import 'package:mymink/core/services/video_service.dart';
import 'package:mymink/features/post/widgets/reel_like_button.dart';
import 'package:mymink/features/post/widgets/reel_save_button.dart';

import 'package:mymink/gen/assets.gen.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ReelItem extends StatefulWidget {
  final PostModel postModel;
  final int index;
  const ReelItem({
    Key? key,
    required this.postModel,
    required this.index,
  }) : super(key: key);

  @override
  _ReelItemState createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> with WidgetsBindingObserver {
  VideoService? _videoService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.postModel.postType == PostType.video.name) {
      _videoService = VideoService()
        ..videoUrl = ApiConstants.getFullVideoURL(widget.postModel.postVideo!);
    }

    if (widget.index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final width = MediaQuery.of(context).size.width;
        final height = MediaQuery.of(context).size.height;

        _videoService?.onVisibilityChanged(
          VisibilityInfo(
            key: Key('post-reel-${widget.postModel.postID}'),
            size: Size(width, height),
            visibleBounds: Rect.fromLTWH(0, 0, width, height),
          ),
        );
      });
    }
  }

  void _viewUserProfile(UserModel? userModel) {
    if (userModel != null) {
      context.push(AppRoutes.viewUserProfilePage, extra: {
        'userModel': userModel,
      });
    }
  }

  @override
  void didUpdateWidget(covariant ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.postModel.postVideo != oldWidget.postModel.postVideo) {
      _videoService?.disposeVideo();
      _videoService?.dispose();
      _videoService = null;
      if (widget.postModel.postType == PostType.video.name) {
        _videoService = VideoService()
          ..videoUrl =
              ApiConstants.getFullVideoURL(widget.postModel.postVideo!);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (widget.postModel.postType == PostType.video.name &&
        _videoService != null) {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive) {
        _videoService?.pauseVideo(); // remembers intent
      } else if (state == AppLifecycleState.resumed) {
        // ✅ Let the service decide if it should resume based on visibility.
        _videoService?.handleAppResumed();

        // Also nudge visibility system so visibleFraction is recomputed.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          VisibilityDetectorController.instance.notifyNow();
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoService?.disposeVideo();
    _videoService?.dispose();
    _videoService = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VideoService>.value(
      value: _videoService!,
      child: Consumer<VideoService>(
        builder: (context, videoService, child) {
          return VisibilityDetector(
            key: Key('reel-item-${widget.postModel.postID}'),
            onVisibilityChanged: (info) {
              videoService.onVisibilityChanged(info);
            },
            child: GestureDetector(
              onTap: videoService.toggleMute,
              child: Stack(alignment: Alignment.center, children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  color: Colors.black,
                  child: AspectRatio(
                    aspectRatio: widget.postModel.postVideoRatio ?? 0.5,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Thumbnail always shown in background
                        CustomImage(
                          imageKey: widget.postModel.videoImage,
                          width: 300,
                          height: 300,
                          boxFit: BoxFit.contain,
                        ),

                        // Video only visible once initialized
                        if (videoService.chewieController != null)
                          AnimatedOpacity(
                            opacity: videoService.chewieController!
                                    .videoPlayerController.value.isInitialized
                                ? 1.0
                                : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Chewie(
                              controller: videoService.chewieController!,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: 12,
                  right: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _viewUserProfile(widget.postModel.userModel);
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ClipOval(
                                    child: CustomImage(
                                        imageKey: widget
                                            .postModel.userModel?.profilePic,
                                        width: 50,
                                        height: 50),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.postModel.userModel?.fullName ??
                                            'Full Name',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: AppColors.white),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.postModel.postCreateDate
                                                ?.timeAgoSinceDate() ??
                                            'a moment ago',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.white),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              if (widget.postModel.caption != null &&
                                  widget.postModel.caption!.isNotEmpty)
                                const SizedBox(height: 20),
                              Text(
                                widget.postModel.caption ?? '',
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.white),
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CustomIconButton(
                                  icon: Assets.images.watchcounticon
                                      .image(width: 36, height: 36),
                                  onPressed: () {}),
                              const SizedBox(height: 4),
                              const Text(
                                '0',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ReelLikeButton(postId: widget.postModel.postID ?? ''),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CustomIconButton(
                                  icon: Assets.images.reelcomment
                                      .image(width: 36, height: 36),
                                  onPressed: () {}),
                              const SizedBox(height: 4),
                              const Text(
                                '0',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ReelSaveButton(postId: widget.postModel.postID ?? ''),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CustomIconButton(
                                  icon: Assets.images.reelshare
                                      .image(width: 36, height: 36),
                                  onPressed: () {}),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CustomIconButton(
                                icon: Assets.images.more6
                                    .image(width: 24, height: 30),
                                onPressed: () {},
                                backgroundColor: AppColors.transparent,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (videoService.showMuteIcon)
                  AnimatedOpacity(
                    opacity: videoService.showMuteIcon ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        MuteUnmute.isMuted ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
              ]),
            ),
          );
        },
      ),
    );
  }
}
