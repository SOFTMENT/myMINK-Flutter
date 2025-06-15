import 'package:flutter/material.dart';
import 'package:mymink/features/post/data/models/post_model.dart';
import 'package:mymink/features/post/widgets/reel_item.dart';

class ReelList extends StatelessWidget {
  final PageController pageController;
  final Future<void> Function() loadMoreReelPosts;
  final List<PostModel> postModels;
  ReelList(
      {super.key,
      required this.pageController,
      required this.postModels,
      required this.loadMoreReelPosts});
  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      physics: const ClampingScrollPhysics(),
      controller: pageController,
      scrollDirection: Axis.vertical,
      itemCount: postModels.length,
      onPageChanged: (index) {
        // When reaching the last page, load more posts.
        if (index == postModels.length - 2) {
          loadMoreReelPosts();
        }
      },
      itemBuilder: (context, index) {
        return ReelItem(postModel: postModels[index]);
      },
    );
  }
}
