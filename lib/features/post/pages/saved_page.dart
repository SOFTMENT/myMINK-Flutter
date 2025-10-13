import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/widgets/progress_hud.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/features/post/data/models/post_model.dart';
import 'package:mymink/features/post/data/services/post_service.dart';
import 'package:mymink/features/post/widgets/grid_post_list.dart';

class SavedPage extends StatefulWidget {
  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoading = false;

  List<PostModel> postModels = [];
  var _error = "No saved posts available";
  final _pageSize = 9;
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore &&
          _lastDocument != null) {
        _fetchPosts();
      }
    });
    loadInitialPosts(true);
  }

  // Load the initial 10 posts
  Future<void> loadInitialPosts(bool shouldShowLoader) async {
    if (shouldShowLoader)
      setState(() {
        _isLoading = true;
      });
    final result = await PostService.getSavedPostsPaginated(
        userID: UserModel.instance.uid ?? '', pageSize: _pageSize);
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
  Future<void> _fetchPosts() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    final result = await PostService.getPostsPaginated(
      pageSize: _pageSize,
      lastDoc: _lastDocument,
      uid: UserModel.instance.uid ?? '',
    );

    if (result.hasData) {
      final newPosts = result.data!.posts;
      _lastDocument = result.data!.lastDocument;
      // If fewer than pageSize posts were returned, there are no more posts.
      if (newPosts.length < _pageSize) {
        _hasMore = false;
      }
      postModels.addAll(newPosts);
    } else {
      _hasMore = false;
      print(result.error);
    }

    setState(() {
      _isLoading = false;
    });

    // If the grid isn’t scrollable (content height less than viewport), fetch more.
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (_scrollController.hasClients &&
    //       _scrollController.position.maxScrollExtent <=
    //           _scrollController.position.viewportDimension &&
    //       _hasMore &&
    //       !_isLoading) {
    //     _fetchPosts();
    //   }
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      GestureDetector(
                        onTap: () {
                          context.pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.3),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_outlined,
                            color: Colors.black,
                            size: 18,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: const Center(
                          child: const Text(
                            'Saved',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textBlack),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width:
                            44, // Adjust this width to match your back button's width
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  GridPostList(
                      posts: postModels,
                      hasMore: _hasMore,
                      scrollController: _scrollController)
                ],
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
              Center(
                child: Text(
                  _error,
                  style:
                      const TextStyle(color: AppColors.textGrey, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
