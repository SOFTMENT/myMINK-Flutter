import 'package:flutter/material.dart';
import 'package:mymink/core/widgets/custom_image.dart';
import 'package:mymink/features/post/data/models/post_model.dart';
import 'package:mymink/features/post/widgets/custom_post_grid_video_item.dart';

/// Decides whether to display an image or video post.
class PostGridItem extends StatelessWidget {
  final PostModel post;
  final bool isBigTile;
  const PostGridItem({Key? key, required this.post, required this.isBigTile})
      : super(key: key);

  getGesture(String? imageUrl) {
    return GestureDetector(
      onTap: () {
        // Navigate to post details if needed.
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CustomImage(
          imageKey: imageUrl,
          width: 200,
          height: 200,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isBigTile && post.postType == 'video') {
      return PostGridVideoItem(post: post);
    } else if (post.postType == 'video') {
      final imageUrl =
          (post.videoImage?.isNotEmpty == true ? post.videoImage : '');
      return getGesture(imageUrl);
    } else {
      final imageUrl =
          (post.postImages?.isNotEmpty == true ? post.postImages!.first : '');
      return getGesture(imageUrl);
    }
  }
}
