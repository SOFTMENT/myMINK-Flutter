import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/services/aws_uploader.dart';

import 'package:mymink/core/widgets/custom_icon_button.dart';

import 'package:mymink/features/post/data/models/post_model.dart';
import 'package:mymink/features/post/data/services/post_service.dart';
import 'package:mymink/features/post/widgets/reel_item.dart';

import 'package:mymink/gen/assets.gen.dart';
import 'package:visibility_detector/visibility_detector.dart';

// NEW: cache
import 'package:mymink/features/post/data/stores/reel_feed_cache.dart';

class ReelPage extends ConsumerStatefulWidget {
  @override
  _ReelPageState createState() => _ReelPageState();
}

class _ReelPageState extends ConsumerState<ReelPage>
    with AutomaticKeepAliveClientMixin<ReelPage> {
  @override
  bool get wantKeepAlive => true;

  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController(); // (unused, but kept)

  List<PostModel> reelPosts = [];
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;

  var _error = "No posts available";

  final ReelFeedCache _cache = ReelFeedCache.instance;

  @override
  void initState() {
    super.initState();

    // Restore from cache if available (no loader, no network)
    if (!_cache.isEmpty) {
      reelPosts = List<PostModel>.from(_cache.posts);
      _lastDocument = _cache.lastDocument;
      _hasMore = _cache.hasMore;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_cache.scrollOffset);
        }
        // ensure visible reel auto-inits/plays
        VisibilityDetectorController.instance.notifyNow();
      });
    }

    // Persist scroll offset & optionally prefetch next page at the end
    _scrollController.addListener(() {
      _cache.scrollOffset = _scrollController.position.pixels;
      // Optional: eager load when nearing end (kept to sentinel builder anyway)
      // final max = _scrollController.position.maxScrollExtent;
      // if (max > 0 && (max - _scrollController.position.pixels) < 300) {
      //   if (_hasMore) loadMoreReelPosts();
      // }
    });
  }

  Future<void> loadInitialReelPosts(bool shouldShowLoader) async {
    final result =
        await PostService.getPostsPaginated(pageSize: 10, postType: 'video');

    if (result.hasData) {
      reelPosts
        ..clear()
        ..addAll(result.data!.posts);
      _lastDocument = result.data!.lastDocument;

      _hasMore = result.data!.posts.length >= 10;

      // update cache
      _cache.posts = List<PostModel>.from(reelPosts);
      _cache.lastDocument = _lastDocument;
      _cache.hasMore = _hasMore;

      setState(() {});
      // kick visibility so top reel auto-plays
      WidgetsBinding.instance.addPostFrameCallback((_) {
        VisibilityDetectorController.instance.notifyNow();
      });
    } else {
      setState(() => _error = result.error!);
    }
  }

  Future<void> loadMoreReelPosts() async {
    if (_lastDocument == null) return;
    if (!_hasMore) return;

    final result = await PostService.getPostsPaginated(
      pageSize: 10,
      lastDoc: _lastDocument,
      postType: 'video',
    );

    if (result.hasData) {
      reelPosts.addAll(result.data!.posts);
      _lastDocument = result.data!.lastDocument;
      _hasMore = result.data!.posts.length >= 10;

      // update cache
      _cache.posts = List<PostModel>.from(reelPosts);
      _cache.lastDocument = _lastDocument;
      _cache.hasMore = _hasMore;

      setState(() {});
      // ensure newly built item visibility is processed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        VisibilityDetectorController.instance.notifyNow();
      });
    } else {
      // keep cache intact on error
    }
  }

  Future<void> _refreshReelPosts() async {
    // reset both state & cache to force a true refresh
    setState(() {
      _lastDocument = null;
      _hasMore = true;
    });
    _cache.clear();
    await loadInitialReelPosts(false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    ref.listen<PostModel?>(PostService.newPostProvider, (previous, next) {
      if (next != null && next.postType == PostType.video) {
        setState(() {
          reelPosts.insert(0, next);

          // update cache on new post
          _cache.posts = List<PostModel>.from(reelPosts);
          // keep lastDocument/hasMore as-is
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          VisibilityDetectorController.instance.notifyNow();
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshReelPosts,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const PageScrollPhysics(),
              slivers: [
                SliverFillViewport(
                  viewportFraction: 1.0,
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= reelPosts.length) {
                        if (_hasMore) loadMoreReelPosts();
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
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

          // Header bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Reels',
                    style: TextStyle(fontSize: 24, color: AppColors.white),
                  ),
                  const Spacer(),
                  CustomIconButton(
                    icon: Assets.images.addreel.image(width: 36, height: 36),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),

          if (reelPosts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 180),
                child: Text(
                  _error,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // persist final position & data
    if (_scrollController.hasClients) {
      _cache.scrollOffset = _scrollController.position.pixels;
    }
    _cache.posts = List<PostModel>.from(reelPosts);
    _cache.lastDocument = _lastDocument;
    _cache.hasMore = _hasMore;

    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}
