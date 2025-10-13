import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:mymink/core/services/firebase_service.dart';
import 'package:mymink/features/post/data/models/post_save_data.dart';
import 'package:mymink/features/post/data/models/post_save_query_params.dart';
import 'package:mymink/features/post/data/services/post_service.dart';
import 'package:mymink/gen/assets.gen.dart';
import 'package:mymink/core/constants/colors.dart';

class ReelSaveButton extends riverpod.ConsumerStatefulWidget {
  final String postId;
  const ReelSaveButton({Key? key, required this.postId}) : super(key: key);

  @override
  _ReelSaveButtonState createState() => _ReelSaveButtonState();
}

class _ReelSaveButtonState extends riverpod.ConsumerState<ReelSaveButton> {
  // Local optimistic state.
  bool? _optimisticSaved;
  int? _optimisticCount;

  @override
  Widget build(BuildContext context) {
    final currentUserUid = FirebaseService().auth.currentUser!.uid;
    final savesAsync = ref.watch(
      PostService.postSaveProvider(
        PostSaveQueryParams(
            postId: widget.postId, currentUserUid: currentUserUid),
      ),
    );
    // Use default value if the stream hasn't produced data.
    final defaultSaves = const PostSaveData(isSaved: false, count: 0);
    final providerSaves = savesAsync.maybeWhen(
      data: (data) => data,
      orElse: () => defaultSaves,
    );
    // Use optimistic state if available.
    final isSaved = _optimisticSaved ?? providerSaves.isSaved;
    final count = _optimisticCount ?? providerSaves.count;

    return GestureDetector(
      onTap: () async {
        print("ReelSaveButton tapped");
        // Immediately update UI optimistically.
        setState(() {
          if (_optimisticSaved ?? providerSaves.isSaved) {
            _optimisticSaved = false;
            _optimisticCount = (_optimisticCount ?? providerSaves.count) - 1;
          } else {
            _optimisticSaved = true;
            _optimisticCount = (_optimisticCount ?? providerSaves.count) + 1;
          }
        });
        await PostService.toggleSave(widget.postId, currentUserUid);
        // Clear optimistic state after a short delay.
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _optimisticSaved = null;
              _optimisticCount = null;
            });
          }
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // For reels, you might want different icons.
          // Here, when saved we display a filled bookmark icon,
          // when not saved we show the regular save icon.
          isSaved
              ? Assets.images.saveFill.image(width: 36, height: 36)
              : Assets.images.save.image(width: 36, height: 36),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
