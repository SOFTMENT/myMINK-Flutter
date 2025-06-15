import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_svg/svg.dart';
import 'package:mymink/core/services/firebase_service.dart';
import 'package:mymink/features/post/data/models/post_save_data.dart';
import 'package:mymink/features/post/data/models/post_save_query_params.dart';
import 'package:mymink/features/post/data/services/post_service.dart';
import 'package:mymink/core/constants/colors.dart';

class SaveButton extends riverpod.ConsumerStatefulWidget {
  final String postId;
  const SaveButton({Key? key, required this.postId}) : super(key: key);

  @override
  _SaveButtonState createState() => _SaveButtonState();
}

class _SaveButtonState extends riverpod.ConsumerState<SaveButton> {
  // Local optimistic state
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
    // Provide a default value if stream hasn’t produced data yet.
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
        // Call Firestore update.
        await PostService.toggleSave(widget.postId, currentUserUid);
        // Optionally clear the optimistic state after a short delay.
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _optimisticSaved = null;
              _optimisticCount = null;
            });
          }
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isSaved
              ? SvgPicture.asset(
                  'assets/images/bookmark-fill.svg',
                  colorFilter: const ColorFilter.mode(
                      Color.fromARGB(255, 152, 152, 152), BlendMode.srcIn),
                  width: 19,
                  height: 19,
                )
              : SvgPicture.asset(
                  'assets/images/bookmark.svg',
                  colorFilter: const ColorFilter.mode(
                      Color.fromARGB(255, 152, 152, 152), BlendMode.srcIn),
                  width: 19,
                  height: 19,
                ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
