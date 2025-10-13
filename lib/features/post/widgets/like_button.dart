import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:mymink/core/services/firebase_service.dart';
import 'package:mymink/features/post/data/models/post_likes_data.dart';
import 'package:mymink/features/post/data/models/post_likes_query_params.dart';
import 'package:mymink/features/post/data/services/post_service.dart';
import 'package:mymink/gen/assets.gen.dart';
import 'package:mymink/core/constants/colors.dart';

class LikeButton extends riverpod.ConsumerStatefulWidget {
  final String postId;
  const LikeButton({Key? key, required this.postId}) : super(key: key);

  @override
  _LikeButtonState createState() => _LikeButtonState();
}

class _LikeButtonState extends riverpod.ConsumerState<LikeButton> {
  // Local optimistic state
  bool? _optimisticLiked;
  int? _optimisticCount;

  @override
  Widget build(BuildContext context) {
    final currentUserUid = FirebaseService().auth.currentUser!.uid;
    final likesAsync = ref.watch(
      PostService.postLikesProvider(
        PostLikesQueryParams(
            postId: widget.postId, currentUserUid: currentUserUid),
      ),
    );

    // Default value if stream hasn’t produced data yet.
    final defaultLikes = const PostLikesData(isLiked: false, count: 0);
    final providerLikes = likesAsync.maybeWhen(
      data: (data) => data,
      orElse: () => defaultLikes,
    );

    // Use the optimistic values if they exist; otherwise use the provider’s data.
    final isLiked = _optimisticLiked ?? providerLikes.isLiked;
    final count = _optimisticCount ?? providerLikes.count;

    // Debug print (you can remove after testing)

    return GestureDetector(
      onTap: () async {
        print("Toggle like tapped");
        // Immediately update UI optimistically.
        setState(() {
          if (_optimisticLiked ?? providerLikes.isLiked) {
            _optimisticLiked = false;
            _optimisticCount = (_optimisticCount ?? providerLikes.count) - 1;
          } else {
            _optimisticLiked = true;
            _optimisticCount = (_optimisticCount ?? providerLikes.count) + 1;
          }
        });
        // Perform Firestore update.
        await PostService.toggleLike(widget.postId, currentUserUid);
        // Optionally, clear the optimistic state after a short delay to let the provider override it.
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _optimisticLiked = null;
              _optimisticCount = null;
            });
          }
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isLiked
              ? Assets.images.smilingFace.image(width: 17, height: 17)
              : Assets.images.happy5.image(width: 17, height: 17),
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
