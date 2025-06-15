import 'package:flutter/material.dart';
import 'package:mymink/core/constants/colors.dart';

class ReplyInputBar extends StatelessWidget {
  final TextEditingController replyController;
  final void Function() postReply;

  ReplyInputBar(
      {super.key, required this.replyController, required this.postReply});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 36),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: replyController,
              minLines: 1,
              maxLines: 4,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Write a reply…',
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryBlue,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              iconSize: 20,
              onPressed: postReply,
            ),
          ),
        ],
      ),
    );
  }
}
