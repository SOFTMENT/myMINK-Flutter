import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/models/search_index.dart';
import 'package:mymink/core/services/algolia_search_service.dart';

import 'package:mymink/core/widgets/custom_segmented_control.dart';
import 'package:mymink/core/widgets/custom_text_button.dart';
import 'package:mymink/core/widgets/dismiss_keyboard_ontap.dart';
import 'package:mymink/core/widgets/progress_hud.dart';
import 'package:mymink/core/widgets/search_bar_with_button.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/features/post/data/models/post_model.dart';
import 'package:mymink/features/post/data/services/post_service.dart';
import 'package:mymink/features/post/widgets/post_search_results.dart';
import 'package:visibility_detector/visibility_detector.dart';

// NEW: cache
import 'package:mymink/features/post/data/stores/search_feed_cache.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({Key? key}) : super(key: key);
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage>
    with AutomaticKeepAliveClientMixin<SearchPage>, WidgetsBindingObserver {
  // Segment
  String selectedSegment = 'Posts';
  @override
  bool get wantKeepAlive => true;
  // Search field
  final TextEditingController searchController = TextEditingController();

  // ----- FEED STATE -----
  // Original (never mutated by search)
  List<PostModel> _basePosts = [];
  dynamic lastPostDoc; // for base feed pagination only
  bool isFetchingPosts = false;
  bool postsHaveMore = true;

  // Search state (separate)
  bool _isSearching = false;
  List<PostModel> _searchResults = [];

  // Users (unchanged)
  List<UserModel> users = [];

  final ScrollController _postsScrollController = ScrollController();

  final SearchFeedCache _cache = SearchFeedCache.instance;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recompute visibleFraction for on-screen tiles so videos can auto-resume.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        VisibilityDetectorController.instance.notifyNow();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Restore from cache if available
    if (!_cache.isBaseEmpty) {
      _basePosts = List<PostModel>.from(_cache.basePosts);
      lastPostDoc = _cache.lastDocument;
      postsHaveMore = _cache.hasMore;

      selectedSegment = _cache.selectedSegment;

      _isSearching = _cache.isSearching;
      _searchResults = List<PostModel>.from(_cache.searchResults);
      searchController.text = _cache.searchText;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_postsScrollController.hasClients) {
          _postsScrollController.jumpTo(_cache.scrollOffset);
        }
        // Ensure any visible video tiles get their visibility callback
        VisibilityDetectorController.instance.notifyNow();
      });
    } else {
      _loadInitialData();
    }

    // paginate ONLY the base feed
    _postsScrollController.addListener(() {
      // persist offset
      _cache.scrollOffset = _postsScrollController.position.pixels;

      if (_isSearching) return; // <-- stop paginating while searching
      if (_postsScrollController.position.pixels >=
              _postsScrollController.position.maxScrollExtent - 200 &&
          postsHaveMore &&
          !isFetchingPosts) {
        _fetchPosts(isInitialLoad: false);
      }
    });

    // When user clears the field, switch back to base feed
    searchController.addListener(() {
      _cache.searchText = searchController.text;
      if (searchController.text.isEmpty) {
        setState(() {
          _isSearching = false;
          _searchResults = _basePosts;

          // update cache
          _cache.isSearching = false;
          _cache.searchResults = List<PostModel>.from(_searchResults);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          VisibilityDetectorController.instance.notifyNow();
        });
      }
    });
  }

  Future<void> _loadInitialData() async {
    await _fetchPosts(isInitialLoad: true);
    // await _fetchUsers();
  }

  Future<void> _fetchPosts({bool isInitialLoad = false}) async {
    if (isFetchingPosts) return;
    setState(() => isFetchingPosts = true);

    const int pageSize = 30;
    final result = await PostService.getPostsPaginated(
      pageSize: pageSize,
      lastDoc: isInitialLoad ? null : lastPostDoc,
      postType: null,
      uid: null,
    );

    if (result.error != null) {
      setState(() => isFetchingPosts = false);
      return;
    }

    final p = result.data!;
    if (isInitialLoad) {
      _basePosts = p.posts; // <-- keep original feed here
      _searchResults = _isSearching ? _searchResults : p.posts;
    } else {
      _basePosts.addAll(p.posts);
      if (!_isSearching) _searchResults.addAll(p.posts);
    }
    lastPostDoc = p.lastDocument;
    postsHaveMore = p.posts.length == pageSize;

    // Update cache
    _cache.basePosts = List<PostModel>.from(_basePosts);
    _cache.lastDocument = lastPostDoc;
    _cache.hasMore = postsHaveMore;

    setState(() => isFetchingPosts = false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      VisibilityDetectorController.instance.notifyNow();
    });
  }

  void _handleShowAll() {
    // Don’t refetch; just exit search mode and show original list again.
    searchController.clear();
    setState(() {
      _isSearching = false;
      _searchResults = _basePosts;
    });

    // cache update
    _cache.isSearching = false;
    _cache.searchText = '';
    _cache.searchResults = List<PostModel>.from(_searchResults);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      VisibilityDetectorController.instance.notifyNow();
    });
  }

  void _handleSearch() async {
    final String searchText = searchController.text.trim();
    if (searchText.isEmpty) {
      _handleShowAll();
      return;
    }
    setState(() => _isSearching = true);

    final result = await algoliaSearch<PostModel>(
      searchText: searchText,
      indexName: SearchIndex.posts,
      filters: 'postType:video OR postType:image',
      fromJson: (m) => PostModel.fromJson(m),
    );

    setState(() {
      _isSearching = false;
      _searchResults = result; // <-- keep base list untouched
    });

    // cache search state
    _cache.isSearching = true;
    _cache.searchText = searchText;
    _cache.searchResults = List<PostModel>.from(result);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      VisibilityDetectorController.instance.notifyNow();
    });
  }

  void _handleSegmentChange(String newValue) {
    setState(() => selectedSegment = newValue);
    _cache.selectedSegment = newValue;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_postsScrollController.hasClients) {
      _cache.scrollOffset = _postsScrollController.position.pixels;
    }
    _cache.basePosts = List<PostModel>.from(_basePosts);
    _cache.lastDocument = lastPostDoc;
    _cache.hasMore = postsHaveMore;

    _cache.isSearching = _isSearching;
    _cache.searchText = searchController.text.trim();
    _cache.searchResults = List<PostModel>.from(_searchResults);

    _postsScrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // If a new post arrives, insert only into the base feed.
    ref.listen<PostModel?>(PostService.newPostProvider, (previous, next) {
      if (next != null) {
        setState(() {
          _basePosts.insert(0, next);
          if (!_isSearching) {
            _searchResults.insert(0, next);
          }
          // cache update
          _cache.basePosts = List<PostModel>.from(_basePosts);
          if (!_isSearching) {
            _cache.searchResults = List<PostModel>.from(_searchResults);
          }
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          VisibilityDetectorController.instance.notifyNow();
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DismissKeyboardOnTap(
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('Search',
                            style: TextStyle(
                              fontSize: 24,
                              color: AppColors.textBlack,
                              fontWeight: FontWeight.bold,
                            )),
                        const Spacer(),
                        CustomTextButton(
                          color: AppColors.textDarkGrey,
                          title: 'Show All',
                          onPressed: _handleShowAll,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SearchBarWithButton(
                      showPadding: false,
                      controller: searchController,
                      onPressed: _handleSearch,
                      hintText: 'Search Posts',
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: CustomSegmentedControl(
                        segments: const ['Posts', 'Users'],
                        initialSelectedSegment: 'Posts',
                        onValueChanged: _handleSegmentChange,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          if (_isSearching) {
                            // In search mode, just stop the spinner.
                            return;
                          }
                          // hard refresh: reset cache & fetch
                          _cache.clearBase();
                          await _fetchPosts(isInitialLoad: true);
                        },
                        child: selectedSegment == 'Posts'
                            ? PostSearchResults(
                                posts:
                                    _isSearching ? _searchResults : _basePosts,
                                scrollController: _postsScrollController,
                                isFetching:
                                    _isSearching ? false : isFetchingPosts,
                              )
                            : PostSearchResults(
                                posts: const [],
                                scrollController: _postsScrollController,
                                isFetching: false,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isSearching) Center(child: ProgressHud()),
          ],
        ),
      ),
    );
  }
}
