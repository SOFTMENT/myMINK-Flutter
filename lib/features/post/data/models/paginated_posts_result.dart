import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mymink/features/post/data/models/post_model.dart';

class PaginatedPostsResult {
  final List<PostModel> posts;
  final DocumentSnapshot lastDocument;

  PaginatedPostsResult({
    required this.posts,
    required this.lastDocument,
  });
}
