import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:go_router/go_router.dart';

import 'package:mymink/core/constants/api_constants.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/services/aws_uploader.dart';
import 'package:mymink/core/services/video_service_home.dart';
import 'package:mymink/core/utils/date_formatter.dart';
import 'package:mymink/core/widgets/custom_icon_button.dart';
import 'package:mymink/core/widgets/custom_image.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/features/post/data/models/post_model.dart';
import 'package:mymink/core/services/video_service.dart';
import 'package:mymink/features/post/widgets/dynamic_image_layout.dart';
import 'package:mymink/features/post/widgets/like_button.dart';
import 'package:mymink/features/post/widgets/save_button.dart';
import 'package:mymink/features/post/widgets/show_post_bottom_sheet.dart';
import 'package:mymink/gen/assets.gen.dart';

import 'package:visibility_detector/visibility_detector.dart';
import 'package:provider/provider.dart' as provider;

class PostItem extends StatefulWidget {
  final PostModel postModel;

  const PostItem({Key? key, required this.postModel}) : super(key: key);

  @override
  _PostItemState createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> with WidgetsBindingObserver {
  VideoServiceHome? _videoService;
  String? enCaption;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.postModel.postType == PostType.video.name) {
      _videoService = VideoServiceHome()
        ..videoUrl = ApiConstants.getFullVideoURL(widget.postModel.postVideo!);
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
  void didUpdateWidget(covariant PostItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.postModel.postVideo != oldWidget.postModel.postVideo) {
      _videoService?.disposeVideo();
      _videoService?.dispose();

      if (widget.postModel.postType == PostType.video.name) {
        _videoService = VideoServiceHome()
          ..videoUrl =
              ApiConstants.getFullVideoURL(widget.postModel.postVideo!);
      }
    }
  }

  // ✅ Same fix as in ReelItem
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (widget.postModel.postType == PostType.video.name &&
        _videoService != null) {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive) {
        _videoService?.pauseVideo(); // remember intent for resume
      } else if (state == AppLifecycleState.resumed) {
        _videoService?.handleAppResumed(); // resume if visible enough
        // Nudge visibility system to recompute visibleFraction
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info.
            Row(
              children: [
                ClipOval(
                  child: GestureDetector(
                    onTap: () {
                      _viewUserProfile(widget.postModel.userModel);
                    },
                    child: CustomImage(
                      imageKey: widget.postModel.userModel?.profilePic,
                      width: 50,
                      height: 50,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    _viewUserProfile(widget.postModel.userModel);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.postModel.userModel?.fullName ?? 'Full Name',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            '${DateFormatter.formatDate(widget.postModel.postCreateDate ?? DateTime.now(), 'dd MMM yyyy')}  ',
                            style: const TextStyle(
                              color: AppColors.primaryRed,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '| ${DateFormatter.formatDate(widget.postModel.postCreateDate ?? DateTime.now(), 'hh:mm a')}  ',
                            style: const TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      if (widget.postModel.bid != null)
                        const SizedBox(height: 3),
                      if (widget.postModel.bid != null &&
                          (widget.postModel.isPromoted != null &&
                              widget.postModel.isPromoted!))
                        Row(
                          children: [
                            Assets.images.certificate
                                .image(width: 16, height: 16),
                            const SizedBox(width: 4),
                            const Text(
                              'Sponsored ',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 50,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: CustomIconButton(
                      icon: const Icon(
                        Icons.more_horiz,
                        color: AppColors.textBlack,
                      ),
                      onPressed: () async {
                        final caption = await showPostBottomSheet(
                            context, widget.postModel);
                        setState(() {
                          enCaption = caption;
                        });
                      },
                      width: 32,
                    ),
                  ),
                )
              ],
            ),
            // Post caption.
            if (widget.postModel.caption != null &&
                widget.postModel.caption!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  enCaption != null
                      ? enCaption!.trim()
                      : widget.postModel.caption!.trim(),
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            // Content: video or image.
            if (widget.postModel.postType == PostType.video.name)
              provider.ChangeNotifierProvider<VideoServiceHome>.value(
                value: _videoService!,
                child: provider.Consumer<VideoServiceHome>(
                  builder: (context, videoService, child) {
                    return VisibilityDetector(
                      key: Key('post-item-${widget.postModel.postID}'),
                      onVisibilityChanged: (info) =>
                          videoService.onVisibilityChanged(info),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: GestureDetector(
                          onTap: videoService.toggleMute,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: AspectRatio(
                                  aspectRatio:
                                      widget.postModel.postVideoRatio ?? 0.5,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      // Thumbnail always shown in background
                                      CustomImage(
                                        imageKey: widget.postModel.videoImage,
                                        width: 300,
                                        height: 300,
                                      ),

                                      // Video only visible once initialized
                                      if (videoService.chewieController != null)
                                        AnimatedOpacity(
                                          opacity: videoService
                                                  .chewieController!
                                                  .videoPlayerController
                                                  .value
                                                  .isInitialized
                                              ? 1.0
                                              : 0.0,
                                          duration:
                                              const Duration(milliseconds: 300),
                                          child: Chewie(
                                            controller:
                                                videoService.chewieController!,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  child: Icon(
                                    MuteUnmute.isMuted
                                        ? Icons.volume_off
                                        : Icons.volume_up,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else if (widget.postModel.postType == PostType.image.name)
              DynamicImageLayout(
                imageUrls: widget.postModel.postImages ?? [],
                imageRatios: widget.postModel.postImagesOrientations ?? [],
              ),
            const SizedBox(height: 10),
            // Post action buttons.
            SizedBox(
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LikeButton(postId: widget.postModel.postID ?? ''),
                          const SizedBox(width: 20),
                          const Text(
                            '|',
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Assets.images.message2.image(width: 19, height: 19),
                          const SizedBox(width: 8),
                          const Text(
                            '0',
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 20),
                          const Text(
                            '|',
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SaveButton(postId: widget.postModel.postID ?? ''),
                          const SizedBox(width: 20),
                          const Text(
                            '|',
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Assets.images.share7.image(width: 20, height: 20),
                          const SizedBox(width: 8),
                          const Text(
                            '0',
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
