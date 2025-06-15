import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/services/aws_uploader.dart';
import 'package:mymink/core/widgets/custom_icon_button.dart';
import 'package:mymink/core/widgets/progress_hud.dart';
import 'package:mymink/features/post/data/models/post_model.dart';
import 'package:mymink/features/post/data/services/post_service.dart';

import 'package:mymink/features/post/widgets/reel_list.dart';
import 'package:mymink/gen/assets.gen.dart';

class ReelPage extends ConsumerStatefulWidget {
  @override
  _ReelPageState createState() => _ReelPageState();
}

class _ReelPageState extends ConsumerState<ReelPage> {
  List<PostModel> reelPosts = [];
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoading = false;
  final PageController _pageController = PageController();
  var _error = "No posts available";
  @override
  void initState() {
    super.initState();
    loadInitialReelPosts(true);
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
          RefreshIndicator(
            onRefresh: _refreshReelPosts,
            child: ReelList(
              pageController: _pageController,
              postModels: reelPosts,
              loadMoreReelPosts: loadMoreReelPosts,
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
    _pageController.dispose();
    super.dispose();
  }
}
