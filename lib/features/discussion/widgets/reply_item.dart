import 'package:flutter/material.dart';

import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/utils/time_ago_extension.dart';
import 'package:mymink/core/widgets/custom_icon_button.dart';
import 'package:mymink/core/widgets/custom_image.dart';
import 'package:mymink/features/discussion/data/models/discussion_reply_model.dart';
import 'package:mymink/features/discussion/data/services/discussion_vote_service.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/features/onboarding/data/services/user_service.dart';

class ReplyItem extends StatefulWidget {
  final DiscussionReply reply;
  final String topicId;
  final void Function(UserModel userModel) userProfileClicked;
  const ReplyItem(Key? key,
      {required this.reply,
      required this.topicId,
      required this.userProfileClicked});

  @override
  State<ReplyItem> createState() => __ReplyItemState();
}

class __ReplyItemState extends State<ReplyItem> {
  late bool _up;
  late bool _down;
  late int _countUp;
  late int _countDown;

  @override
  void initState() {
    super.initState();
    _loadFromReply();
  }

  @override
  void didUpdateWidget(covariant ReplyItem old) {
    super.didUpdateWidget(old);
    // if Flutter decided to reuse this State with a different Reply,
    // re-initialize our fields
    if (old.reply.id != widget.reply.id) {
      _loadFromReply();
    }
  }

  void _loadFromReply() {
    final me = UserModel.instance.uid!;
    _up = widget.reply.upvotedBy.contains(me);
    _down = widget.reply.downvotedBy.contains(me);
    _countUp = widget.reply.upvotes;
    _countDown = widget.reply.downvotes;
  }

  void _onVote(bool isUp) {
    setState(() {
      if (isUp) {
        if (_up) {
          _up = false;
          _countUp--;
        } else {
          _up = true;
          _countUp++;
          if (_down) {
            _down = false;
            _countDown--;
          }
        }
      } else {
        if (_down) {
          _down = false;
          _countDown--;
        } else {
          _down = true;
          _countDown++;
          if (_up) {
            _up = false;
            _countUp--;
          }
        }
      }
    });
    DiscussionVoteService.voteReply(
      topicId: widget.topicId,
      replyId: widget.reply.id,
      isUpvote: isUp,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder(
          future: UserService.getUserByUid(uid: widget.reply.uid),
          builder: (ctx, snap) {
            if (snap.hasData && snap.data!.data != null) {
              final user = snap.data!.data!;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: GestureDetector(
                  onTap: () {
                    widget.userProfileClicked(user);
                  },
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(88),
                        child: CustomImage(
                          imageKey: user.profilePic,
                          width: 40,
                          height: 40,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            widget.reply.createdAt.timeAgoSinceDate(),
                            style: const TextStyle(
                                color: AppColors.textGrey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 29, right: 25),
          child:
              Text(widget.reply.content, style: const TextStyle(fontSize: 13)),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Row(
            children: [
              CustomIconButton(
                icon: Icon(
                  _up ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                  color: _up ? AppColors.primaryBlue : Colors.grey,
                  size: 18,
                ),
                onPressed: () => _onVote(true),
              ),
              Text('$_countUp'),
              const SizedBox(width: 16),
              CustomIconButton(
                icon: Icon(
                  _down ? Icons.thumb_down_rounded : Icons.thumb_down_outlined,
                  color: _down ? AppColors.primaryRed : Colors.grey,
                  size: 18,
                ),
                onPressed: () => _onVote(false),
              ),
              Text(
                '$_countDown',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        const Divider(
          thickness: 3,
          color: Color.fromARGB(153, 234, 231, 231),
        )
      ],
    );
  }
}
