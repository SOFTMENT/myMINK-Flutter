// lib/features/discussion/data/services/discussion_reply_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mymink/features/discussion/data/models/discussion_reply_model.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';

class DiscussionReplyService {
  static final _db = FirebaseFirestore.instance;

  /// Add a brand-new reply under [topicId].
  static Future<void> addReply({
    required String topicId,
    required String content,
  }) async {
    final uid = UserModel.instance.uid!;
    final now = DateTime.now();

    final reply = DiscussionReply(
      id: '', // Firestore will assign
      topicId: topicId,
      uid: uid,
      content: content,
      createdAt: now,
      upvotes: 0,
      downvotes: 0,

      upvotedBy: [],
      downvotedBy: [],
    );

    await _db
        .collection('Discussions')
        .doc(topicId)
        .collection('replies')
        .add(reply.toMap());

    await _db.collection('Discussions').doc(topicId).set({
      'replyCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }
}
