// features/discussion/data/models/discussion_topic_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class DiscussionTopic {
  final String id;
  final String title;
  final String description;
  final String uid;
  final DateTime createdAt;
  final int replyCount;

  DiscussionTopic({
    required this.id,
    required this.title,
    required this.description,
    required this.uid,
    required this.createdAt,
    required this.replyCount,
  });

  factory DiscussionTopic.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Safely convert Timestamp → DateTime, default to now() if missing
    final ts = data['createdAt'];
    final created = ts is Timestamp ? ts.toDate() : DateTime.now();

    return DiscussionTopic(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      uid: data['uid'] ?? '',
      createdAt: created,
      replyCount: data['replyCount'] ?? 0,
    );
  }
}
