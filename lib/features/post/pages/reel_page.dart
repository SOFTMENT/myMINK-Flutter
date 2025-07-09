import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mymink/core/constants/api_constants.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/services/aws_uploader.dart';
import 'package:mymink/core/services/my_video_cache_manager.dart';
import 'package:mymink/core/widgets/custom_icon_button.dart';
import 'package:mymink/core/widgets/progress_hud.dart';
import 'package:mymink/features/post/data/models/post_model.dart';
import 'package:mymink/features/post/data/services/post_service.dart';
import 'package:mymink/features/post/widgets/reel_item.dart';

import 'package:mymink/features/post/widgets/reel_list.dart';
import 'package:mymink/gen/assets.gen.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ReelPage extends ConsumerStatefulWidget {
  @override
  _ReelPageState createState() => _ReelPageState();
}

class _ReelPageState extends ConsumerState<ReelPage>
    with AutomaticKeepAliveClientMixin<ReelPage> {
  @override
  bool get wantKeepAlive => true;
  List<PostModel> reelPosts = [];
  final ScrollController _scrollController = ScrollController();
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoading = false;
  final PageController _pageController = PageController();
  var _error = "No posts available";
  @override
  void initState() {
    super.initState();

    loadInitialReelPosts(true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      VisibilityDetectorController.instance.notifyNow();
    });
  }

  Future<void> loadInitialReelPosts(bool shouldShowLoader) async {
    if (shouldShowLoader)
      setState(() {
        _isLoading = true;
      });
    final result =
        await PostService.getPostsPaginated(pageSize: 10, postType: 'video');
    if (shouldShowLoader)
      setState(() {
        _isLoading = false;
      });
    if (result.hasData) {
      reelPosts.clear();
      reelPosts.addAll(result.data!.posts);
      _lastDocument = result.data!.lastDocument;
      if (result.data!.posts.length < 10) _hasMore = false;

      setState(() {});
    } else {
      setState(() {
        _error = result.error!;
      });
    }
  }

  Future<void> loadMoreReelPosts() async {
    if (!_hasMore) return;
    final result = await PostService.getPostsPaginated(
        pageSize: 10, lastDoc: _lastDocument, postType: 'video');
    if (result.hasData) {
      reelPosts.addAll(result.data!.posts);
      _lastDocument = result.data!.lastDocument;
      if (result.data!.posts.length < 10) _hasMore = false;

      setState(() {});
    } else {
      // handle error if needed
    }
  }

  Future<void> _refreshReelPosts() async {
    setState(() {
      _lastDocument = null;
      _hasMore = true;
    });
    await loadInitialReelPosts(false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    ref.listen<PostModel?>(PostService.newPostProvider, (previous, next) {
      if (next != null && next.postType == PostType.video) {
        setState(() {
          reelPosts.insert(0, next);
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1) Replace your RefreshIndicator child:
          RefreshIndicator(
            onRefresh: _refreshReelPosts,
            child: CustomScrollView(
              controller: _scrollController, // <-- use a ScrollController
              physics: const PageScrollPhysics(),
              slivers: [
                // (Optional) a header sliver goes here:
                // SliverToBoxAdapter(child: getYourHeader()),

                // 2) SliverFillViewport gives you full‐screen pages, one at a time:
                SliverFillViewport(
                  viewportFraction: 1.0,
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      // When you hit the “extra” slot at the end, trigger load-more:
                      if (index >= reelPosts.length) {
                        if (_hasMore) loadMoreReelPosts();
                        return const Center(child: CircularProgressIndicator());
                      }
                      // Otherwise build your reel item:
                      return ReelItem(
                        postModel: reelPosts[index],
                        index: index,
                      );
                    },
                    childCount: reelPosts.length + (_hasMore ? 1 : 0),
                  ),
                ),
              ],
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Reels',
                    style: TextStyle(
                      fontSize: 24,
                      color: AppColors.white,
                    ),
                  ),
                  const Spacer(),
                  CustomIconButton(
                      icon: Assets.images.addreel.image(width: 36, height: 36),
                      onPressed: () {}),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 100),
                child: ProgressHud(),
              ),
            )
          else if (reelPosts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 180),
                child: Text(
                  _error,
                  style:
                      const TextStyle(color: AppColors.textGrey, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}
