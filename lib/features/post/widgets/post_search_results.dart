import 'package:flutter/material.dart';

import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'package:mymink/features/post/data/models/post_model.dart';
import 'package:mymink/features/post/widgets/custom_post_grid_item.dart';

/// Updated PostSearchResults remains the same as before.
class PostSearchResults extends StatelessWidget {
  final List<PostModel> posts;
  final ScrollController scrollController;
  final bool isFetching;

  const PostSearchResults({
    Key? key,
    required this.posts,
    required this.scrollController,
    required this.isFetching,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty && isFetching) {
      return const Center(child: CircularProgressIndicator());
    } else if (posts.isEmpty) {
      return const Center(child: Text("No posts found"));
    }

    // Repeating pattern for the custom grid layout.
    final pattern = [
      // Group 1: small tile, big tile, small tile.
      const QuiltedGridTile(1, 1),
      const QuiltedGridTile(2, 2),
      const QuiltedGridTile(1, 1),
      // Group 2: 6 small tiles (2 rows of 3)
      const QuiltedGridTile(2, 2),
      const QuiltedGridTile(1, 1),

      const QuiltedGridTile(1, 1),
      // Group 3: big tile then two small tiles.

      const QuiltedGridTile(1, 1),
      const QuiltedGridTile(2, 2),
      const QuiltedGridTile(1, 1),
      // Group 2: 6 small tiles (2 rows of 3)
      const QuiltedGridTile(2, 2),
      const QuiltedGridTile(1, 1),

      const QuiltedGridTile(1, 1),
    ];

    return GridView.custom(
      controller: scrollController,
      gridDelegate: SliverQuiltedGridDelegate(
        crossAxisCount: 3, // 3 columns
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        pattern: pattern,
        repeatPattern: QuiltedGridRepeatPattern.same,
      ),
      childrenDelegate: SliverChildBuilderDelegate(
        (context, index) {
          final tile = pattern[index % pattern.length];
          final isBigTile = tile.crossAxisCount == 2 && tile.mainAxisCount == 2;

          if (index == posts.length && isFetching) {
            return const Center(child: CircularProgressIndicator());
          }
          final post = posts[index];
          return PostGridItem(
            post: post,
            isBigTile: isBigTile,
          );
        },
        childCount: posts.length + (isFetching ? 1 : 0),
      ),
    );
  }
}
