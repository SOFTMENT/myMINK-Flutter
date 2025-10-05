import 'package:flutter/material.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/utils/time_ago_extension.dart';
import 'package:mymink/core/widgets/custom_image.dart';

class ChatBubble extends StatelessWidget {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isAnimated;
  final String? profilePicUrl;
  final String? senderName;
  final bool showSenderName;
  final bool isVideoCall;

  const ChatBubble({
    super.key,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isAnimated = false,
    this.senderName,
    this.profilePicUrl,
    this.showSenderName = true,
  }) : isVideoCall = content == '*--||videocall||--*';

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser && profilePicUrl != null)
            Padding(
              padding: const EdgeInsets.only(right: 6, top: 2),
              child: SizedBox(
                  height: 38,
                  width: 38,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(120),
                      child: CustomImage(
                          imageKey: profilePicUrl, width: 100, height: 100))),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isUser && senderName != null && showSenderName)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      senderName!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isUser
                          ? isVideoCall
                              ? const Color.fromARGB(255, 0, 64, 124)
                              : AppColors.primaryBlue
                          : isVideoCall
                              ? const Color.fromARGB(255, 255, 212, 212)
                              : const Color.fromARGB(186, 255, 255, 255),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isVideoCall)
                          Icon(
                            Icons.videocam,
                            color: isUser ? Colors.white : Colors.black,
                          ),
                        if (isVideoCall)
                          const SizedBox(
                            width: 4,
                          ),
                        Flexible(
                          child: Text(
                            isVideoCall ? 'Video Call' : content,
                            style: TextStyle(
                              fontSize: 15,
                              color: isUser
                                  ? Colors.white
                                  : const Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                        ),
                      ],
                    )),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, right: 6, left: 6),
                  child: Text(
                    timestamp.timeAgoSinceDate(),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
