import 'package:flutter/material.dart';
import 'package:mymink/features/post/data/models/post_model.dart';
import 'package:mymink/features/post/widgets/reel_item.dart';
import 'package:visibility_detector/visibility_detector.dart';

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
      key: const PageStorageKey('reel_posts_list'),
      physics: const ClampingScrollPhysics(),
      controller: pageController,
      scrollDirection: Axis.vertical,
      itemCount: postModels.length,
      onPageChanged: (index) {
        // 1) load more when near the end
        if (index >= postModels.length - 2) {
          loadMoreReelPosts();
        }
        // 2) re-report visibility so the newly-visible reel starts immediately
        VisibilityDetectorController.instance.notifyNow();
      },
      itemBuilder: (context, index) => ReelItem(
        postModel: postModels[index],
        index: index,
      ),
    );
  }
}
