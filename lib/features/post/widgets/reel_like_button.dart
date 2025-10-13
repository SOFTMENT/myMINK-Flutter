import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:mymink/core/services/firebase_service.dart';
import 'package:mymink/features/post/data/models/post_likes_data.dart';
import 'package:mymink/features/post/data/models/post_likes_query_params.dart';
import 'package:mymink/features/post/data/services/post_service.dart';
import 'package:mymink/gen/assets.gen.dart';
import 'package:mymink/core/constants/colors.dart';

class ReelLikeButton extends riverpod.ConsumerWidget {
  final String postId;
  const ReelLikeButton({Key? key, required this.postId}) : super(key: key);

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final currentUserUid = FirebaseService().auth.currentUser!.uid;
    final likesAsync = ref.watch(
      PostService.postLikesProvider(
        PostLikesQueryParams(postId: postId, currentUserUid: currentUserUid),
      ),
    );

    // Provide a default value if no data is available yet.
    final defaultLikes = const PostLikesData(isLiked: false, count: 0);
    final likesData = likesAsync.maybeWhen(
      data: (data) => data,
      orElse: () => defaultLikes,
    );

    // For reels, unliked state uses the "unhappy" icon, liked uses "smilingFace"
    final icon = likesData.isLiked
        ? Assets.images.happy.image(width: 36, height: 36)
        : Assets.images.unhappy.image(width: 36, height: 36);

    return GestureDetector(
      onTap: () async {
        print("Reel like tapped");
        await PostService.toggleLike(postId, currentUserUid);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 4),
          Text(
            '${likesData.count}',
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
