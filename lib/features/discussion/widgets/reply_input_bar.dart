import 'package:flutter/material.dart';

class ReplyInputBar extends StatelessWidget {
  final TextEditingController replyController;
  final void Function() postReply;
  final String hint;

  ReplyInputBar(
      {super.key,
      required this.replyController,
      required this.postReply,
      required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 36),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: replyController,
              minLines: 1,
              maxLines: 4,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
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
