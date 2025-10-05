import 'package:flutter/material.dart';

import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/utils/time_ago_extension.dart';
import 'package:mymink/core/widgets/custom_image.dart';
import 'package:mymink/features/discussion/data/models/discussion_topic_model.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/features/onboarding/data/services/user_service.dart';

class TopicHeader extends StatelessWidget {
  final DiscussionTopic discussionTopic;
  final void Function(UserModel userModel) userProfileClicked;
  TopicHeader(
      {super.key,
      required this.discussionTopic,
      required this.userProfileClicked});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    return FutureBuilder(
      future: UserService.getUserByUid(uid: discussionTopic.uid),
      builder: (ctx, snap) {
        Widget header = const SizedBox.shrink();
        if (snap.hasData && snap.data!.data != null) {
          final user = snap.data!.data!;
          header = GestureDetector(
            onTap: () {
              userProfileClicked(user);
            },
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(54),
                  child: CustomImage(
                    imageKey: user.profilePic,
                    width: 40,
                    height: 40,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName ?? 'Unknown',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color.fromARGB(255, 0, 0, 0)),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      discussionTopic.createdAt.timeAgoSinceDate(),
                      style: const TextStyle(
                          color: AppColors.textGrey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        return Container(
          color: const Color.fromARGB(255, 255, 255, 255),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, left: 25, right: 25),
                child: header,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Text(
                  discussionTopic.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color.fromARGB(255, 0, 0, 0)),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Text(
                  discussionTopic.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDarkGrey,
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              const Divider(
                  height: 4,
                  thickness: 4,
                  color: Color.fromARGB(255, 219, 219, 219))
            ],
          ),
        );
      },
    );
  }
}
