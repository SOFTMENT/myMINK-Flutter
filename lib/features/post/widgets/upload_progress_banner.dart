import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mymink/features/post/data/services/post_service.dart';

class UploadProgressBanner extends ConsumerWidget {
  /// Optional thumbnail URL (for image or video).
  final String? thumbnailUrl;

  const UploadProgressBanner({Key? key, this.thumbnailUrl}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(PostService.postUploadStatusProvider);
    final progress = ref.watch(PostService.postUploadProgressProvider) + 0.1;

    // Show only when uploading or done.
    if (status == PostUploadStatus.uploading ||
        status == PostUploadStatus.success) {
      // Compute the progress fraction for success state as 1.0.
      final double displayProgress =
          (status == PostUploadStatus.success) ? 1.0 : progress;

      return Row(
        children: [
          // ClipRRect(
          //   borderRadius: BorderRadius.circular(8),
          //   child: CustomImage(
          //       imageKey: UserModel.instance.profilePic, width: 50, height: 50),
          // ),

          // const SizedBox(width: 12),

          // 2. Title and progress bar in a column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title text (e.g. "Posting...")
                Text(
                  displayProgress == 1.0 ? 'Posted' : 'Posting...',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                const SizedBox(height: 8),
                // 3. Progress bar
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Light pink background track
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(115, 239, 233, 233),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth * displayProgress;
                        //final width = 160.0;
                        return Container(
                          width: width,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 38, 152, 240),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // If status is idle or error, hide the bar.
      return const SizedBox.shrink();
    }
  }
}
