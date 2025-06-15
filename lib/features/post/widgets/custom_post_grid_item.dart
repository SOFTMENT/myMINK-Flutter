import 'package:flutter/material.dart';
import 'package:mymink/core/widgets/custom_image.dart';
import 'package:mymink/features/post/data/models/post_model.dart';
import 'package:mymink/features/post/widgets/custom_post_grid_video_item.dart';

/// Decides whether to display an image or video post.
class PostGridItem extends StatelessWidget {
  final PostModel post;
  const PostGridItem({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (post.postType == 'video') {
      return PostGridVideoItem(post: post);
    } else {
      final imageUrl =
          (post.postImages?.isNotEmpty == true ? post.postImages!.first : '');
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
  }
}
