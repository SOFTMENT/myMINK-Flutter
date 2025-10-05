// lib/features/livestreaming/services/livestream_service.dart

import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/collections.dart';

import 'package:mymink/features/onboarding/data/models/user_model.dart';
import 'package:mymink/features/livestreaming/data/models/live_streaming_model.dart';
import 'package:mymink/features/videocall/data/services/video_call_services.dart';

class LivestreamService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static final _functions = FirebaseFunctions.instance;

  /// Calls your callable function to delete all audience docs
  static Future<void> _deleteAllAudiences(String uid) async {
    final callable =
        _functions.httpsCallable('deleteLivestreamingAllAudiences');
    final result = await callable.call(<String, dynamic>{'uid': uid});
    if (result.data['error'] != null) {
      throw Exception(result.data['error']);
    }
  }

  /// Starts the live stream, writes to Firestore, then navigates to the Join screen
  static Future<void> startLiveStream(
    BuildContext context, {
    bool shouldShowProgress = false,
  }) async {
    final uid = _auth.currentUser!.uid;

    try {
      // 1) Clear any old audience entries via callable
      await _deleteAllAudiences(uid);

      final token = VideoCallService.agoraToken;

      if (token == null) {
        return;
      }

      // 3) Write / update the liveStreamings doc
      await _db.collection(Collections.liveStreamings).doc(uid).set({
        'token': token,
        'fullName': UserModel.instance.fullName ?? '',
        'profilePic': UserModel.instance.profilePic ?? '',
        'uid': uid,
        'isOnline': true,
        'date': Timestamp.fromDate(DateTime.now()),
      });

      LiveStreamingModel liveStreamingModel = LiveStreamingModel(
          uid: uid,
          fullName: UserModel.instance.fullName ?? '',
          profilePic: UserModel.instance.profilePic ?? '',
          date: DateTime.now(),
          token: token,
          isOnline: true,
          agoraUID: 0,
          count: 0,
          likeCount: 0);

      context.push(AppRoutes.joinLivestreamPage,
          extra: {'liveStreamModel': liveStreamingModel});
    } catch (e) {
      // on error, hide loader if shown

      // optionally rethrow or show a SnackBar:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start live stream: $e')),
      );
    }
  }
}
