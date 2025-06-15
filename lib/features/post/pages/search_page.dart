import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/utils/common_input_decoration.dart';
import 'package:mymink/core/widgets/custom_icon_button.dart';
import 'package:mymink/core/widgets/custom_segmented_control.dart';
import 'package:mymink/core/widgets/custom_text_button.dart';
import 'package:mymink/core/widgets/dismiss_keyboard_ontap.dart';
import 'package:mymink/core/widgets/search_bar_with_button.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/features/post/data/models/post_model.dart';
import 'package:mymink/features/post/data/services/post_service.dart';
import 'package:mymink/features/post/widgets/post_search_results.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({Key? key}) : super(key: key);
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  // Segment selection state
  String selectedSegment = 'Posts';

  // Search TextField controller
  final TextEditingController searchController = TextEditingController();

  // Posts data
  List<PostModel> posts = [];
  dynamic lastPostDoc; // Firestore DocumentSnapshot type
  bool isFetchingPosts = false;
  bool postsHaveMore = true;

  // Users data
  List<UserModel> users = [];

  // Scroll controller for posts grid (for pagination)
  final ScrollController _postsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    _postsScrollController.addListener(() {
      // When user scrolls near the bottom, attempt to fetch more posts
      if (_postsScrollController.position.pixels >=
              _postsScrollController.position.maxScrollExtent - 200 &&
          postsHaveMore &&
          !isFetchingPosts) {
        _fetchPosts(isInitialLoad: false);
      }
    });
  }

  Future<void> _loadInitialData() async {
    await _fetchPosts(isInitialLoad: true);
    await _fetchUsers();
  }

  Future<void> _fetchPosts({bool isInitialLoad = false}) async {
    if (isFetchingPosts) return;
    setState(() {
      isFetchingPosts = true;
    });
    const int pageSize = 30;
    final result = await PostService.getPostsPaginated(
      pageSize: pageSize,
      lastDoc: isInitialLoad ? null : lastPostDoc,
      postType: null,
      uid: null,
    );
    if (result.error != null) {
      // Handle error as needed
      setState(() {
        isFetchingPosts = false;
      });
      return;
    }
    final paginatedResult = result.data!;
    if (isInitialLoad) {
      posts = paginatedResult.posts;
    } else {
      posts.addAll(paginatedResult.posts);
    }
    lastPostDoc = paginatedResult.lastDocument;
    postsHaveMore = paginatedResult.posts.length == pageSize;
    setState(() {
      isFetchingPosts = false;
    });
  }

  Future<void> _fetchUsers() async {
    // final result = await PostService.getLatestUsers();
    // if (result.error == null) {
    //   setState(() {
    //     users = result.data!;
    //   });
    // }
  }

  void _handleShowAll() {
    searchController.clear();
    // Reset posts and users to initial data
    _fetchPosts(isInitialLoad: true);
    _fetchUsers();
  }

  void _handleSearch() async {
    final String searchText = searchController.text.trim();
    if (searchText.isEmpty) {
      _handleShowAll();
      return;
    }
    // // Optionally, show a progress indicator
    // final List<PostModel> searchPostsResult =
    //     await PostService.searchPosts(searchText);
    // final List<UserModel> searchUsersResult =
    //     await DataService.searchUsers(searchText);
    // setState(() {
    //   posts = searchPostsResult;
    //   users = searchUsersResult;
    // });
  }

  void _handleSegmentChange(String newValue) {
    setState(() {
      selectedSegment = newValue;
    });
  }

  @override
  void dispose() {
    _postsScrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PostModel?>(PostService.newPostProvider, (previous, next) {
      if (next != null) {
        setState(() {
          posts.insert(0, next);
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DismissKeyboardOnTap(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Header with title and "Show All" button
                Row(
                  children: [
                    const Text(
                      'Search',
                      style: TextStyle(
                        fontSize: 24,
                        color: AppColors.textBlack,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    CustomTextButton(
                      color: AppColors.textDarkGrey,
                      title: 'Show All',
                      onPressed: _handleShowAll,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Search text field and search icon button
                SearchBarWithButton(
                    showPadding: false,
                    controller: searchController,
                    onPressed: _handleSearch,
                    hintText: 'Search Posts'),
                const SizedBox(height: 20),
                // Custom segmented control to switch between Posts and Users
                SizedBox(
                  width: double.infinity,
                  child: CustomSegmentedControl(
                    segments: ['Posts', 'Users'],
                    initialSelectedSegment: 'Posts',
                    onValueChanged: _handleSegmentChange,
                  ),
                ),
                const SizedBox(height: 10),
                // Display container based on selected segment
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _fetchPosts(isInitialLoad: true);
                    },
                    child: selectedSegment == 'Posts'
                        ? PostSearchResults(
                            posts: posts,
                            scrollController: _postsScrollController,
                            isFetching: isFetchingPosts,
                          )
                        : PostSearchResults(
                            posts: [],
                            scrollController: _postsScrollController,
                            isFetching: isFetchingPosts,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
