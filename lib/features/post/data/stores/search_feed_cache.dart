import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mymink/features/post/data/models/post_model.dart';

class SearchFeedCache {
  SearchFeedCache._();
  static final SearchFeedCache instance = SearchFeedCache._();

  // Base feed (default/“Posts” segment)
  List<PostModel> basePosts = [];
  DocumentSnapshot? lastDocument;
  bool hasMore = true;

  // UI state
  double scrollOffset = 0.0;
  String selectedSegment = 'Posts';

  // Search state
  bool isSearching = false;
  String searchText = '';
  List<PostModel> searchResults = [];

  bool get isBaseEmpty => basePosts.isEmpty;

  void clearBase() {
    basePosts = [];
    lastDocument = null;
    hasMore = true;
  }

  void clearSearch() {
    isSearching = false;
    searchText = '';
    searchResults = [];
  }

  void clearAll() {
    clearBase();
    clearSearch();
    scrollOffset = 0.0;
    selectedSegment = 'Posts';
  }
}
