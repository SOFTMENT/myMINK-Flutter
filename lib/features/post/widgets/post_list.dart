import 'package:flutter/material.dart';

import 'package:mymink/features/post/data/models/post_model.dart';
import 'package:mymink/features/post/widgets/post_item.dart';

class PostList extends StatelessWidget {
  final List<PostModel> postModels;
  final bool isFetching;
  PostList({super.key, required this.postModels, required this.isFetching});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // while fetching, show a loader at the end
          if (index >= postModels.length) {
            return const Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final post = postModels[index];
          return PostItem(key: ValueKey(post.postID), postModel: post);
        },
        childCount: postModels.length + (isFetching ? 1 : 0),
      ),
    );
  }
}
