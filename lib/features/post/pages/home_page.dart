import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/colors.dart';

import 'package:mymink/core/utils/common_input_decoration.dart';
import 'package:mymink/core/widgets/custom_icon_button.dart';
import 'package:mymink/core/widgets/custom_image.dart';
import 'package:mymink/core/widgets/progress_hud.dart';

import 'package:mymink/features/post/data/models/post_model.dart';
import 'package:mymink/features/post/data/services/post_service.dart';
import 'package:mymink/features/post/data/stores/home_feed_cache.dart';
import 'package:mymink/features/post/data/stores/reel_feed_cache.dart';

import 'package:mymink/features/post/widgets/create_post_sheet_content.dart';

import 'package:mymink/features/post/widgets/post_list.dart';
import 'package:mymink/features/post/widgets/upload_progress_banner.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/features/post/widgets/weather_widget.dart';

import 'package:mymink/gen/assets.gen.dart';

class HomePage extends riverpod.ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends riverpod.ConsumerState<HomePage>
    with AutomaticKeepAliveClientMixin<HomePage> {
  @override
  bool get wantKeepAlive => true;
  final userModel = UserModel.instance;
  var _error = "No posts available";
  var _isLoading = false;

  var _isFetching = false;
  List<PostModel> postModels = [];
  final int _pageSize = 10;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  final HomeFeedCache _cache = HomeFeedCache.instance;

  @override
  void initState() {
    super.initState();

    // 1) Restore from cache immediately if available (no loader, no network)
    if (!_cache.isEmpty) {
      postModels = List<PostModel>.from(_cache.posts);
      _lastDocument = _cache.lastDocument;
      _hasMore = _cache.hasMore;

      // Schedule scroll restore after first frame to ensure list is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_cache.scrollOffset);
        }
      });
    } else {
      loadInitialPosts(true);
      loadInitialReelPosts(false);
    }

    // Track scroll (persist offset on every change)
    _scrollController.addListener(_scrollListener);
  }

  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _refreshIndicatorKey.currentState?.show();
    }
  }

  // Listen to scroll events to trigger loading more posts
  void _scrollListener() {
    // Save scroll offset to cache
    _cache.scrollOffset = _scrollController.position.pixels;

    // Trigger pagination
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore &&
        _lastDocument != null) {
      loadMorePosts();
    }
  }

  // Pull-to-refresh callback
  Future<void> _refreshPosts() async {
    setState(() {
      _lastDocument = null;
      _hasMore = true;
    });
    _cache.clear();
    await loadInitialPosts(false);
  }

  // Load the initial 10 posts
  Future<void> loadInitialPosts(bool shouldShowLoader) async {
    if (shouldShowLoader) {
      setState(() => _isLoading = true);
    }

    final result = await PostService.getPostsPaginated(pageSize: _pageSize);

    if (shouldShowLoader) {
      setState(() => _isLoading = false);
    }

    if (result.hasData) {
      postModels
        ..clear()
        ..addAll(result.data!.posts);
      _lastDocument = result.data!.lastDocument;
      _hasMore = result.data!.posts.length >= _pageSize;

      // Update cache
      _cache.posts = List<PostModel>.from(postModels);
      _cache.lastDocument = _lastDocument;
      _cache.hasMore = _hasMore;
      // keep scrollOffset as-is (likely 0 on fresh load)
      if (!mounted) return;

      setState(() {});
    } else {
      setState(() => _error = result.error!);
    }
  }

  Future<void> loadInitialReelPosts(bool shouldShowLoader) async {
    ReelFeedCache reelFeedCache = ReelFeedCache.instance;
    final result =
        await PostService.getPostsPaginated(pageSize: 10, postType: 'video');
    List<PostModel> reelPosts = [];
    if (result.hasData) {
      reelPosts
        ..clear()
        ..addAll(result.data!.posts);
      _lastDocument = result.data!.lastDocument;
      _hasMore = result.data!.posts.length >= 10;

      // update cache
      reelFeedCache.posts = List<PostModel>.from(reelPosts);
      reelFeedCache.lastDocument = _lastDocument;
      reelFeedCache.hasMore = _hasMore;
    }
  }

  // Load the next 10 posts
  void loadMorePosts() async {
    if (!_hasMore || _isFetching) return;

    setState(() => _isFetching = true);

    final result = await PostService.getPostsPaginated(
      pageSize: _pageSize,
      lastDoc: _lastDocument,
    );

    setState(() => _isFetching = false);

    if (result.hasData) {
      postModels.addAll(result.data!.posts);
      _lastDocument = result.data!.lastDocument;
      _hasMore = result.data!.posts.length >= _pageSize;

      // Update cache
      _cache.posts = List<PostModel>.from(postModels);
      _cache.lastDocument = _lastDocument;
      _cache.hasMore = _hasMore;

      setState(() {});
    } else {
      // keep cache intact on error
      debugPrint(result.error);
    }
  }

  Widget getheader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Assets.images.logo.image(height: 77, width: 77),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(top: 25),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const WeatherWidget(),
                  const SizedBox(
                    width: 4,
                  ),
                  CustomIconButton(
                      icon:
                          Assets.images.tablerScan.image(width: 20, height: 20),
                      onPressed: () {
                        context.push(AppRoutes.userQrcodePage);
                      }),
                  const SizedBox(
                    width: 4,
                  ),
                  CustomIconButton(
                      icon: Assets.images.notificationWhite
                          .image(width: 20, height: 20),
                      onPressed: () {}),
                  const SizedBox(
                    width: 4,
                  ),
                  CustomIconButton(
                      icon: Assets.images.messageWhite
                          .image(width: 20, height: 20),
                      onPressed: () {
                        context.push(AppRoutes.inboxPage);
                      }),
                  const SizedBox(
                    width: 4,
                  ),
                  CustomIconButton(
                      icon: Assets.images.addWhite.image(width: 20, height: 20),
                      onPressed: () {
                        showCreatePostSheet(context: context);
                      }),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 10, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome',
                        style: TextStyle(
                            color: Color.fromARGB(211, 255, 255, 255),
                            fontSize: 17),
                      ),
                      const SizedBox(
                        height: 1,
                      ),
                      Text(
                        userModel.fullName ?? 'Full Name',
                        style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ClipOval(
                    child: CustomImage(
                      imageKey: userModel.profilePic,
                      width: 80,
                      height: 80,
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                height: 42,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        textCapitalization: TextCapitalization.words,
                        autocorrect: false,
                        maxLines: 1,
                        minLines: 1,
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(
                            color: AppColors.white, fontSize: 13),
                        decoration: buildInputDecoration(
                            labelText: "Search Posts",
                            isWhiteOrder: true,
                            fillColor: Colors.transparent,
                            prefixColor: AppColors.white,
                            focusedBorderColor:
                                const Color.fromARGB(255, 255, 255, 255)
                                    .withValues(alpha: 0.7),
                            prefixIcon: Icons.search_outlined),
                      ),
                    ),
                    const SizedBox(
                      width: 6,
                    ),
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: CustomIconButton(
                          icon: const Align(
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.search,
                              color: AppColors.white,
                              size: 25,
                            ),
                          ),
                          backgroundColor: AppColors.primaryRed,
                          onPressed: () {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              const UploadProgressBanner(),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.listen<PostModel?>(PostService.newPostProvider, (previous, next) {
      if (next != null && next.bid == null) {
        setState(() {
          Future.delayed(const Duration(milliseconds: 500), () {
            ref.read(PostService.newPostProvider.notifier).state = null;
          });
          postModels.insert(0, next);

          _cache.posts = List<PostModel>.from(postModels);
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Assets.images.homebg.image(width: double.infinity),
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 30, 15, 0),
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _refreshPosts,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // 1. Your header
                  SliverToBoxAdapter(child: getheader()),

                  // 2. The list of posts
                  PostList(postModels: postModels, isFetching: _isFetching),
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
          else if (postModels.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 180),
                  child: Text(
                    _error,
                    style: const TextStyle(
                        color: AppColors.textGrey, fontSize: 13),
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
    // Save final scroll offset & data before this tab is disposed
    if (_scrollController.hasClients) {
      _cache.scrollOffset = _scrollController.position.pixels;
    }
    _cache.posts = List<PostModel>.from(postModels);
    _cache.lastDocument = _lastDocument;
    _cache.hasMore = _hasMore;

    _scrollController.dispose();
    super.dispose();
  }
}
