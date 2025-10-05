import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';

import 'package:mymink/core/services/aws_uploader.dart';
import 'package:mymink/core/widgets/custom_image.dart';
import 'package:mymink/features/post/data/models/post_model.dart';

class GridPostList extends StatelessWidget {
  final List<PostModel> posts;
  final bool hasMore;
  final ScrollController? scrollController;

  const GridPostList({
    Key? key,
    required this.posts,
    required this.hasMore,
    this.scrollController = null,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If more posts are expected, add an extra cell for a loader.
    int itemCount = posts.length + (hasMore ? 1 : 0);
    return GridView.builder(
      shrinkWrap: true,
      controller: scrollController,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 columns for a 3x3 grid
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1, // square cells
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Loader cell at the end.
        if (posts.isEmpty) {
          return Container();
        }

        if (index == posts.length) {
          return const Center(child: CircularProgressIndicator());
        }
        final post = posts[index];
        String? imageUrl;
        if (post.postType == PostType.video.name) {
          // For video posts, you might later replace this with thumbnail-generation logic.
          imageUrl = post.videoImage;
        } else if (post.postType == PostType.image.name) {
          // For image posts, use the first image.
          if (post.postImages != null && post.postImages!.isNotEmpty) {
            imageUrl = post.postImages!.first;
          }
        }
        return GestureDetector(
          onTap: () {
            context.push(AppRoutes.userPostsPage,
                extra: {'index': index, 'postModels': posts});
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CustomImage(
              imageKey: imageUrl,
              width: 125,
              height: 125,
            ),
          ),
        );
      },
    );
  }
}
