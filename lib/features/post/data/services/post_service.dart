import 'dart:io';

import 'package:flutter/foundation.dart'; // ✅ This provides `compute`
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mymink/core/constants/account_type.dart';
import 'package:mymink/core/constants/api_constants.dart';
import 'package:mymink/core/constants/collections.dart';
import 'package:mymink/core/services/aws_uploader.dart';
import 'package:mymink/core/services/deep_link_service.dart';
import 'package:mymink/core/services/image_service.dart';
import 'package:mymink/core/services/video_service.dart';
import 'package:mymink/core/utils/result.dart';

import 'package:mymink/features/post/data/models/paginated_posts_result.dart';
import 'package:mymink/features/post/data/models/post_likes_data.dart';
import 'package:mymink/features/post/data/models/post_likes_query_params.dart';
import 'package:mymink/features/post/data/models/post_model.dart';
import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/features/post/data/models/post_save_data.dart';
import 'package:mymink/features/post/data/models/post_save_query_params.dart';
import 'package:image/image.dart' as img;
import 'package:mymink/features/post/data/stores/home_feed_cache.dart';
import 'package:mymink/features/post/data/stores/reel_feed_cache.dart';

enum PostUploadStatus {
  idle, // Not uploading
  uploading, // Currently uploading
  success, // Upload completed
  error, // Upload failed
}

class PostService {
  static double calculateAspectRatio(Uint8List imageBytes) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return 1.0;
    return decoded.width / decoded.height;
  }

  // Singleton instance
  static final PostService _instance = PostService._internal();

  // Private constructor
  PostService._internal();

  // Factory constructor
  factory PostService() => _instance;

  // Firebase Firestore instance
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Add a new post
  static Future<Result<void>> addPost(PostModel postModel) async {
    try {
      // Add the post data to Firestore
      await _db
          .collection(Collections.posts)
          .doc(postModel.postID)
          .set(postModel.toJson());

      return Result(data: null);
    } catch (e) {
      return Result(error: e.toString());
    }
  }

  static final newPostProvider = StateProvider<PostModel?>((ref) => null);

  /// Tracks the current status of the post upload.

  /// Holds the current post upload status.
  static final postUploadStatusProvider =
      StateProvider<PostUploadStatus>((ref) => PostUploadStatus.idle);

  /// Holds the current upload progress as a double [0..1].
  static final postUploadProgressProvider = StateProvider<double>((ref) => 0.0);
  static final postSaveProvider =
      StreamProvider.family<PostSaveData, PostSaveQueryParams>((ref, params) {
    return FirebaseFirestore.instance
        .collection(Collections.posts)
        .doc(params.postId)
        .collection(Collections.savePosts)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs;
      final count = docs.length;
      final isSaved = docs.any((doc) => doc.id == params.currentUserUid);
      return PostSaveData(isSaved: isSaved, count: count);
    }).distinct((prev, next) =>
            prev.count == next.count && prev.isSaved == next.isSaved);
  });

  // Toggle save function: if already saved, remove it; otherwise, save it.
  static Future<void> toggleSave(String postId, String currentUserUid) async {
    final postSaveDocRef = FirebaseFirestore.instance
        .collection(Collections.posts)
        .doc(postId)
        .collection(Collections.savePosts)
        .doc(currentUserUid);
    final userSaveDocRef = FirebaseFirestore.instance
        .collection(Collections.users)
        .doc(currentUserUid)
        .collection(Collections.savePosts)
        .doc(postId);

    final snapshot = await postSaveDocRef.get();
    if (snapshot.exists) {
      // Already saved → unsave.
      await postSaveDocRef.delete();
      await userSaveDocRef.delete();
    } else {
      final data = {
        'date': FieldValue.serverTimestamp(),
        'postId': postId,
        'userId': currentUserUid,
      };
      await postSaveDocRef.set(data);
      await userSaveDocRef.set(data);
    }
  }

  static final uploadProgressProvider = StateProvider<double>((ref) => 0.0);

  static final postLikesProvider =
      StreamProvider.family<PostLikesData, PostLikesQueryParams>((ref, params) {
    return FirebaseFirestore.instance
        .collection(Collections.posts)
        .doc(params.postId)
        .collection(Collections.likes)
        .snapshots() // Removed includeMetadataChanges
        .map((snapshot) {
      final docs = snapshot.docs;
      final count = docs.length;
      final isLiked = docs.any((doc) => doc.id == params.currentUserUid);
      return PostLikesData(isLiked: isLiked, count: count);
    }).distinct((prev, next) =>
            prev.count == next.count && prev.isLiked == next.isLiked);
  });

  static Future<void> toggleLike(String postId, String currentUserUid) async {
    final likeDocRef = FirebaseFirestore.instance
        .collection(Collections.posts)
        .doc(postId)
        .collection(Collections.likes)
        .doc(currentUserUid);

    final stopwatch = Stopwatch()..start();
    final docSnapshot = await likeDocRef.get();
    print("toggleLike: get() completed in ${stopwatch.elapsedMilliseconds} ms");

    if (docSnapshot.exists) {
      print("toggleLike: like exists, deleting...");
      await likeDocRef.delete();
      print("toggleLike: deletion complete");
    } else {
      print("toggleLike: like does not exist, creating...");
      await likeDocRef.set({
        'userId': currentUserUid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("toggleLike: creation complete");
    }
    print("toggleLike: finished");
  }

  static Future<Result<PaginatedPostsResult>> getSavedPostsPaginated({
    required String userID,
    int pageSize = 10,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      final db = FirebaseFirestore.instance;

      // Step 1: Fetch saved post documents from the user's savePosts subcollection.
      Query<Map<String, dynamic>> savedPostsQuery = db
          .collection(Collections.users)
          .doc(userID)
          .collection(Collections.savePosts)
          .orderBy('date', descending: false)
          .limit(pageSize);

      if (lastDoc != null) {
        savedPostsQuery = savedPostsQuery.startAfterDocument(lastDoc);
      }

      final snapshot = await savedPostsQuery.get();

      if (snapshot.docs.isNotEmpty) {
        // Extract the post IDs from the saved posts.
        final postIDs = snapshot.docs
            .map((doc) {
              final data = doc.data();
              return data['postId'] as String?;
            })
            .where((id) => id != null)
            .cast<String>()
            .toList();

        // Step 2: Fetch each post document concurrently.
        final postsRef = db.collection(Collections.posts);
        final posts = await Future.wait(postIDs.map((postID) async {
          final postDoc = await postsRef.doc(postID).get();
          if (postDoc.exists && postDoc.data() != null) {
            return PostModel.fromJson(postDoc.data()!);
          }
          return null;
        }).toList());

        // Filter out any null posts.
        final filteredPosts = posts.whereType<PostModel>().toList();

        // Use the last document of the savedPosts query for pagination.
        final lastDocument = snapshot.docs.last;

        return Result(
          data: PaginatedPostsResult(
              posts: filteredPosts, lastDocument: lastDocument),
        );
      }

      return Result(error: 'No saved posts available');
    } catch (e) {
      print(e);
      return Result(error: e.toString());
    }
  }

  static Future<Result<PaginatedPostsResult>> getPostsPaginated({
    int pageSize = 10,
    DocumentSnapshot? lastDoc,
    AccountType accountType = AccountType.user,
    String? postType, // Optional parameter for filtering by post type
    String? uid = null,
    // Optional parameter for filtering by user ID
  }) async {
    try {
      // Build the base query
      Query<Map<String, dynamic>> query = _db
          .collection(Collections.posts)
          .orderBy('postCreateDate', descending: true)
          .where('isActive', isEqualTo: true);

      if (accountType == AccountType.user) {
        query = query.where('isPromoted', isEqualTo: true);
      }
      // If uid is provided, filter posts by uid.
      if (uid != null && uid.isNotEmpty) {
        query = query
            .where(accountType == AccountType.user ? 'uid' : 'bid',
                isEqualTo: uid)
            .where('bid',
                isNull: accountType == AccountType.user ? true : false);
      }

      // Apply the postType filter if provided (e.g. 'video' for reel posts)
      if (postType != null) {
        query = query.where('postType', isEqualTo: postType);
      }

      query = query.limit(pageSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      // Execute the query
      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        // Convert each document to a PostModel
        final posts = await Future.wait(snapshot.docs.map((doc) async {
          final post = PostModel.fromJson(doc.data());

          if (post.postType == PostType.video.name &&
              post.postVideo != null &&
              post.postVideo!.isNotEmpty) {
            VideoService.downloadVideoInCache(
                ApiConstants.getFullVideoURL(post.postVideo!));
          }

          // Optionally, fetch the UserModel for this post
          if (post.uid != null && post.uid!.isNotEmpty) {
            try {
              final userDoc =
                  await _db.collection(Collections.users).doc(post.uid).get();
              if (userDoc.exists) {
                post.userModel = UserModel.fromJson(userDoc.data()!);
              }
            } catch (e) {
              print('Error fetching user for post: ${post.uid}, error: $e');
            }
          }
          return post;
        }).toList());

        // The last document from the snapshot (used for pagination)
        final lastDocument = snapshot.docs.last;

        return Result(
          data: PaginatedPostsResult(posts: posts, lastDocument: lastDocument),
        );
      }

      return Result(error: 'No posts available');
    } catch (e) {
      print(e);
      return Result(error: e.toString());
    }
  }

  static Future<void> startUploadAndPushPost({
    required BuildContext context,
    required ProviderContainer container, // New parameter instead of WidgetRef
    required PostModel postModel,
    required List<File> files,
    required PostType postType,
    File? thumbnailFile, // Used only for video posts
    double? postVideoRatio, // Used only for video posts
  }) async {
    // Use container to get the progress and status notifiers.
    final progressNotifier =
        container.read(postUploadProgressProvider.notifier);
    final statusNotifier = container.read(postUploadStatusProvider.notifier);

    // 1. Mark the status as uploading and reset progress to 0.0.
    statusNotifier.state = PostUploadStatus.uploading;
    progressNotifier.state = 0.0;

    if (postType == PostType.image) {
      List<String> photoURLs = [];
      List<double> orientations = [];

      for (var photo in files) {
        // Compress and convert the image.
        File? compressPhoto =
            await ImageService.compressAndConvertImage(imageFile: photo);
        if (compressPhoto != null) {
          // 2. Upload the image with a progress callback.
          final result = await AWSUploader.uploadFile(
            context: context,
            photo: compressPhoto,
            folderName: 'PostImages',
            postType: postType,
            onProgress: (progress) {
              // Update progress (0.0 to 1.0).
              progressNotifier.state = progress;
            },
          );

          // 3. Check result.
          if (result.hasData) {
            // Decode the image to calculate aspect ratio.
            final bytes = await compressPhoto.readAsBytes();
            final aspectRatio = await compute(calculateAspectRatio, bytes);
            orientations.add(aspectRatio);
            photoURLs.add(result.data!);
          } else {
            statusNotifier.state = PostUploadStatus.error;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result.error!)),
            );
            return;
          }
        }
      }
      postModel.postImages = photoURLs;
      postModel.postImagesOrientations = orientations;
    } else if (postType == PostType.video) {
      // For video posts, first check for required thumbnail and ratio.
      if (thumbnailFile == null || postVideoRatio == null) {
        statusNotifier.state = PostUploadStatus.error;
        return;
      }

      AWSUploader.uploadFile(
        context: context,
        photo: thumbnailFile,
        folderName: 'PostImages',
        postType: PostType.image,
        onProgress: (progress) {},
      ).then((thumbResult) {
        if (thumbResult.hasData) {
          postModel.videoImage = thumbResult.data!;
        } else {
          statusNotifier.state = PostUploadStatus.error;

          return;
        }
      });

      final compressedVideoFile =
          await ImageService.compressVideoSafely(files.first);

      if (compressedVideoFile == null) return;

      // Now upload the video file.
      final videoResult = await AWSUploader.uploadFileCloudinary(
        context: context,
        video: compressedVideoFile,
        folderName: 'PostVideos',
        onProgress: (progress) {
          progressNotifier.state = progress;
        },
      );
      if (videoResult.hasData) {
        postModel.postVideo = videoResult.data!;
        postModel.postVideoRatio = postVideoRatio;
      } else {
        print('UPLOAD ERROR: ${videoResult.error}');
        statusNotifier.state = PostUploadStatus.error;

        return;
      }

      await VideoService.downloadVideoInCache(
          ApiConstants.getFullVideoURL(postModel.postVideo!));
    }

    // Reset progress after upload.
    progressNotifier.state = 0.0;

    // Mark upload as successful.
    statusNotifier.state = PostUploadStatus.success;

    // Hide the "Posted!" banner after 2 seconds.
    Future.delayed(const Duration(milliseconds: 600), () {
      statusNotifier.state = PostUploadStatus.idle;
    });

    final deepLinkResult =
        await DeepLinkService.createDeepLinkForPost(postModel);
    if (deepLinkResult.hasData) {
      postModel.shareURL = deepLinkResult.data;
    }

    // Finally, push the post to Firebase.
    final firebaseResult = await PostService.addPost(postModel);
    if (firebaseResult.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(firebaseResult.error!)),
      );
    } else {
      postModel.userModel = UserModel.instance;
      container.read(newPostProvider.notifier).state = postModel;
    }
  }

  // Load the initial 10 posts
  static Future<void> loadInitialHomePosts(int pageSize) async {
    final result = await PostService.getPostsPaginated(pageSize: pageSize);

    final HomeFeedCache _cache = HomeFeedCache.instance;

    if (result.hasData) {
      // Update cache
      _cache.posts = List<PostModel>.from(result.data!.posts);
      _cache.lastDocument = result.data!.lastDocument;
      _cache.hasMore = result.data!.posts.length >= pageSize;

      // keep scrollOffset as-is (likely 0 on fresh load)
    }

    return;
  }

  static Future<void> loadInitialReelPosts(int pageSize) async {
    ReelFeedCache reelFeedCache = ReelFeedCache.instance;
    final result = await PostService.getPostsPaginated(
        pageSize: pageSize, postType: 'video');

    if (result.hasData) {
      // update cache
      reelFeedCache.posts = result.data!.posts;
      reelFeedCache.lastDocument = result.data!.lastDocument;
      reelFeedCache.hasMore = result.data!.posts.length >= pageSize;
    }

    print(reelFeedCache.isEmpty);
    return;
  }
}
