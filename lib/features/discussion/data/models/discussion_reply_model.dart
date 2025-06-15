// lib/features/discussion/data/models/discussion_reply_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class DiscussionReply {
  final String id;
  final String topicId;
  final String uid;
  final String content;
  final DateTime createdAt;
  final int upvotes;
  final int downvotes;
  final List<String> upvotedBy;
  final List<String> downvotedBy;

  DiscussionReply({
    required this.id,
    required this.topicId,
    required this.uid,
    required this.content,
    required this.createdAt,
    required this.upvotes,
    required this.downvotes,
    required this.upvotedBy,
    required this.downvotedBy,
  });

  factory DiscussionReply.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DiscussionReply(
      id: doc.id,
      topicId: data['topicId'] ?? '',
      uid: data['uid'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      upvotes: data['upvotes'] ?? 0,
      downvotes: data['downvotes'] ?? 0,
      upvotedBy: List<String>.from(data['upvotedBy'] ?? <String>[]),
      downvotedBy: List<String>.from(data['downvotedBy'] ?? <String>[]),
    );
  }

  Map<String, dynamic> toMap() => {
        'topicId': topicId,
        'uid': uid,
        'content': content,
        'createdAt': Timestamp.fromDate(createdAt),
        'upvotes': upvotes,
        'downvotes': downvotes,
        'upvotedBy': upvotedBy,
        'downvotedBy': downvotedBy,
      };
}
