import 'package:flutter/material.dart';

import 'package:mymink/core/utils/time_ago_extension.dart';
import 'package:mymink/core/widgets/custom_image.dart';

import 'package:mymink/features/inbox/data/models/last_message.dart';

class InboxWidget extends StatelessWidget {
  final LastMessage lastMessage;
  final void Function() onTap;
  const InboxWidget({required this.lastMessage, required this.onTap});

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
                    child: Text(lastMessage.senderName ?? 'Sender Name',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  Text(lastMessage.date!.timeAgoSinceDate(),
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),

              const SizedBox(height: 12),
              // creator + replies + votes
              Row(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(200)),
                        child: CustomImage(
                            imageKey: lastMessage.senderImage,
                            width: 30,
                            height: 30),
                      ),
                      const SizedBox(width: 6),
                      Text(lastMessage.senderName ?? 'Sender Name',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
