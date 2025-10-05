import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mymink/features/post/data/models/post_model.dart';

class ReelFeedCache {
  ReelFeedCache._();
  static final ReelFeedCache instance = ReelFeedCache._();

  List<PostModel> posts = [];
  DocumentSnapshot? lastDocument;
  bool hasMore = true;

  // scroll position for SliverFillViewport (pixels)
  double scrollOffset = 0.0;

  bool get isEmpty => posts.isEmpty;

  void clear() {
    posts = [];
    lastDocument = null;
    hasMore = true;
    scrollOffset = 0.0;
  }
}
