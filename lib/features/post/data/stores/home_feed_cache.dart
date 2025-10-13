// lib/features/post/data/stores/home_feed_cache.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mymink/features/post/data/models/post_model.dart';

class HomeFeedCache {
  HomeFeedCache._();
  static final HomeFeedCache instance = HomeFeedCache._();

  List<PostModel> posts = [];
  DocumentSnapshot? lastDocument;
  bool hasMore = true;
  double scrollOffset = 0.0;
  bool hydrated = false; // whether UI has restored from cache at least once

  bool get isEmpty => posts.isEmpty;
  void clear() {
    posts = [];
    lastDocument = null;
    hasMore = true;
    scrollOffset = 0.0;
    hydrated = false;
  }
}
