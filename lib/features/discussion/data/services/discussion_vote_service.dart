// lib/features/discussion/data/services/discussion_vote_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';

class DiscussionVoteService {
  static final _db = FirebaseFirestore.instance;

  /// Toggle an up- or down-vote on a single reply.
  /// If the user had already voted the same way, this *removes* it.
  static Future<void> voteReply({
    required String topicId,
    required String replyId,
    required bool isUpvote,
  }) async {
    final uid = UserModel.instance.uid!;
    final ref = _db
        .collection('Discussions')
        .doc(topicId)
        .collection('replies')
        .doc(replyId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data()!;
      final upvotedBy = List<String>.from(data['upvotedBy'] ?? []);
      final downvotedBy = List<String>.from(data['downvotedBy'] ?? []);
      var upvotes = data['upvotes'] ?? 0;
      var downvotes = data['downvotes'] ?? 0;

      if (isUpvote) {
        if (upvotedBy.contains(uid)) {
          // remove upvote
          upvotedBy.remove(uid);
          upvotes--;
        } else {
          upvotedBy.add(uid);
          upvotes++;
          // if previously downvoted, undo it
          if (downvotedBy.remove(uid)) downvotes--;
        }
      } else {
        if (downvotedBy.contains(uid)) {
          downvotedBy.remove(uid);
          downvotes--;
        } else {
          downvotedBy.add(uid);
          downvotes++;
          if (upvotedBy.remove(uid)) upvotes--;
        }
      }

      tx.update(ref, {
        'upvotedBy': upvotedBy,
        'downvotedBy': downvotedBy,
        'upvotes': upvotes,
        'downvotes': downvotes,
      });
    });
  }
}
