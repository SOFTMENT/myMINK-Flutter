import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/utils/time_ago_extension.dart';
import 'package:mymink/core/widgets/custom_image.dart';
import 'package:mymink/features/discussion/data/models/discussion_topic_model.dart';

class TopicCard extends StatelessWidget {
  final DiscussionTopic topic;
  final void Function() onTap;
  const TopicCard({required this.topic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0.5,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // title + time
              Row(
                children: [
                  Expanded(
                    child: Text(topic.title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Text(topic.createdAt.timeAgoSinceDate(),
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 4),
              // description preview
              Text(
                topic.description.length > 100
                    ? '${topic.description.substring(0, 100)}…'
                    : topic.description,
                style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              // creator + replies + votes
              Row(
                children: [
                  // creator avatar + name
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('Users')
                        .doc(topic.uid)
                        .get(),
                    builder: (ctx, usnap) {
                      if (!usnap.hasData) return const SizedBox(width: 24);
                      final data = usnap.data!.data() as Map<String, dynamic>;
                      return Row(
                        children: [
                          ClipRRect(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(200)),
                            child: CustomImage(
                                imageKey: data['profilePic'],
                                width: 30,
                                height: 30),
                          ),
                          const SizedBox(width: 6),
                          Text(data['fullName'] ?? '…',
                              style: const TextStyle(fontSize: 12)),
                        ],
                      );
                    },
                  ),
                  const Spacer(),
                  // replies
                  const Icon(Icons.chat_bubble_outline,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${topic.replyCount}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
