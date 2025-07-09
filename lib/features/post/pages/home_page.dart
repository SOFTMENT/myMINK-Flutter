import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/api_constants.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/services/aws_uploader.dart';
import 'package:mymink/core/services/my_video_cache_manager.dart';
import 'package:mymink/core/services/notification_service.dart';
import 'package:mymink/core/utils/common_input_decoration.dart';
import 'package:mymink/core/widgets/custom_icon_button.dart';
import 'package:mymink/core/widgets/custom_image.dart';
import 'package:mymink/core/widgets/progress_hud.dart';

import 'package:mymink/features/post/data/models/post_model.dart';
import 'package:mymink/features/post/data/services/post_service.dart';
import 'package:mymink/features/post/widgets/post_item.dart';
import 'package:mymink/features/post/widgets/upload_progress_banner.dart';
import 'package:mymink/features/post/widgets/post_bottom_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:mymink/features/post/widgets/post_list.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/features/post/widgets/weather_widget.dart';
import 'package:mymink/features/weather/data/models/weather_model.dart';
import 'package:mymink/features/weather/widgets/weather_report_sheet.dart';
import 'package:mymink/gen/assets.gen.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

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

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_scrollListener);
    loadInitialPosts(true);
  }

  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _refreshIndicatorKey.currentState!.show();
    }
  }

  // Listen to scroll events to trigger loading more posts
  void _scrollListener() {
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
    await NotificationService.showLocalNotification(
        id: 22221, title: 'Vaibhav', body: 'Sharma');
    // Reset the pagination state
    setState(() {
      _lastDocument = null;
      _hasMore = true;
    });
    // Re-fetch the initial posts
    await loadInitialPosts(false);
  }

  // Load the initial 10 posts
  Future<void> loadInitialPosts(bool shouldShowLoader) async {
    if (shouldShowLoader)
      setState(() {
        _isLoading = true;
      });
    final result = await PostService.getPostsPaginated(pageSize: _pageSize);
    if (shouldShowLoader)
      setState(() {
        _isLoading = false;
      });
    if (result.hasData) {
      postModels.clear();
      postModels.addAll(result.data!.posts);
      _lastDocument = result.data!.lastDocument;
      if (result.data!.posts.length < _pageSize) {
        _hasMore = false;
      }

      setState(() {});
    } else {
      setState(() {
        _error = result.error!;
      });
    }
  }

  // Load the next 10 posts
  void loadMorePosts() async {
    if (!_hasMore || _isFetching) return;

    setState(() {
      _isFetching = true;
    });

    final result = await PostService.getPostsPaginated(
      pageSize: _pageSize,
      lastDoc: _lastDocument,
    );

    setState(() {
      _isFetching = false;
    });

    if (result.hasData) {
      postModels.addAll(result.data!.posts);
      _lastDocument = result.data!.lastDocument;
      if (result.data!.posts.length < _pageSize) {
        _hasMore = false;
      }

      setState(() {});
    } else {
      print(result.error);
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
                        PostBottomSheet.showCustomBottomSheet(context);
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
      if (next != null) {
        setState(() {
          Future.delayed(const Duration(milliseconds: 500), () {
            ref.read(PostService.newPostProvider.notifier).state = null;
          });
          postModels.insert(0, next);
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
                  SliverList(
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
                        return PostItem(
                            key: ValueKey(post.postID), postModel: post);
                      },
                      childCount: postModels.length + (_isFetching ? 1 : 0),
                    ),
                  ),
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
    _scrollController.dispose();
    super.dispose();
  }
}
