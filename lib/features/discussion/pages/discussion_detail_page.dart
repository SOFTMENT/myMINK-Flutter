// lib/features/discussion/pages/discussion_detail_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';

import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/widgets/custom_app_bar.dart';

import 'package:mymink/core/widgets/dismiss_keyboard_ontap.dart';
import 'package:mymink/features/discussion/data/models/discussion_reply_model.dart';
import 'package:mymink/features/discussion/data/models/discussion_topic_model.dart';
import 'package:mymink/features/discussion/data/services/discussion_reply_service.dart';
import 'package:mymink/features/discussion/widgets/reply_input_bar.dart';

import 'package:mymink/features/discussion/widgets/reply_item.dart';
import 'package:mymink/features/discussion/widgets/topic_header.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';

class DiscussionDetailPage extends StatefulWidget {
  final DiscussionTopic topic;
  const DiscussionDetailPage({Key? key, required this.topic}) : super(key: key);

  @override
  State<DiscussionDetailPage> createState() => _DiscussionDetailPageState();
}

class _DiscussionDetailPageState extends State<DiscussionDetailPage> {
  final _replyCtrl = TextEditingController();

  late Stream<List<DiscussionReply>> _repliesStream;

  @override
  void initState() {
    super.initState();
    _repliesStream = FirebaseFirestore.instance
        .collection('Discussions')
        .doc(widget.topic.id)
        .collection('replies')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => DiscussionReply.fromDoc(d)).toList());
  }

  void _userProfileClicked(UserModel userModel) {
    context
        .push(AppRoutes.viewUserProfilePage, extra: {'userModel': userModel});
  }

  Future<void> _postReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;
    _replyCtrl.clear();
    await DiscussionReplyService.addReply(
      topicId: widget.topic.id,
      content: text,
    );
    // scroll to bottom is handled by the ListView automatically
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // subtle grey
      body: DismissKeyboardOnTap(
        child: Column(
          children: [
            CustomAppBar(title: 'Discussion'),
            Expanded(
              child: StreamBuilder<List<DiscussionReply>>(
                stream: _repliesStream,
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final replies = snap.data ?? [];
                  return ListView.separated(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.all(0),
                    itemCount: replies.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (ctx, i) {
                      if (i == 0)
                        return TopicHeader(
                          discussionTopic: widget.topic,
                          userProfileClicked: (userModel) {
                            _userProfileClicked(userModel);
                          },
                        );
                      final reply = replies[i - 1];
                      return ReplyItem(
                        ValueKey(reply.id),
                        reply: reply,
                        topicId: widget.topic.id,
                        userProfileClicked: (userModel) {
                          _userProfileClicked(userModel);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            ReplyInputBar(
              replyController: _replyCtrl,
              postReply: _postReply,
              hint: 'Write a reply...',
            ),
          ],
        ),
      ),
    );
  }
}
