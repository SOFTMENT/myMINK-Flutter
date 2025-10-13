// lib/features/livestreaming/widgets/live_stream_card.dart
import 'package:flutter/material.dart';
import 'package:mymink/core/widgets/custom_image.dart';

import 'package:mymink/features/livestreaming/data/models/live_streaming_model.dart';

class LiveStreamCard extends StatelessWidget {
  final LiveStreamingModel live;
  final VoidCallback onTap;

  const LiveStreamCard({
    super.key,
    required this.live,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFB0BED9), // grey-blue bg
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // center circle
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 80,
                height: 80,
                child: live.profilePic.isEmpty
                    ? const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.grey,
                      )
                    : CustomImage(
                        imageKey: live.profilePic, width: 100, height: 100),
              ),
            ),

            // top-left: full name pill
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63), // pink
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  live.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // top-right: eye + count
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.remove_red_eye,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${live.count}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
