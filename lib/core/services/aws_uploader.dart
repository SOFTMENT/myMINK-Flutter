import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:aws_common/vm.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:flutter/material.dart';
import 'package:mymink/core/constants/api_constants.dart';
import 'package:mymink/core/services/cloudinary_rest.dart';

import 'package:mymink/core/utils/result.dart';

typedef ProgressCallback = void Function(double progress);

class AWSUploader {
  static OverlayEntry? _overlayEntry;
  static bool _isDialogVisible = false;
  static String _latestProgress = "0"; // Store latest progress

  // Show or update the progress dialog
  static void showProgressDialog(
      BuildContext context, String progressPercentage) {
    _latestProgress = progressPercentage; // Update progress text

    if (_isDialogVisible) {
      _updateProgress(); // If already visible, update instead of recreating
      return;
    }

    _isDialogVisible = true;

    _overlayEntry = OverlayEntry(
      builder: (context) => _buildOverlay(),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  // Hide the progress dialog
  static void hideProgressDialog() {
    if (_isDialogVisible) {
      _isDialogVisible = false;
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  // Update progress text inside the existing overlay without stacking
  static void _updateProgress() {
    _overlayEntry?.markNeedsBuild();
  }

  // Build overlay UI with updated progress
  static Widget _buildOverlay() {
    return Stack(
      children: [
        Container(
          color: Colors.black.withValues(alpha: 0.4), // Dim background
        ),
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black
                    .withValues(alpha: 0.8), // Semi-transparent black
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(width: 20),
                  StatefulBuilder(
                    builder: (context, setState) {
                      return Text(
                        'Uploading: $_latestProgress%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Check explicit content in an image using Firebase Function
  static Future<bool> checkExplicitImage(String image) async {
    try {
      final data = {'image': image};
      final result = await FirebaseFunctions.instance
          .httpsCallable('checkExplicitImage')
          .call(data);

      final resultData = result.data as Map<String, dynamic>;
      if (resultData.containsKey('isExplicit')) {
        return resultData['isExplicit'] as bool;
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      return false;
    }
  }

  static Future<Result<String?>> uploadFileCloudinary({
    required BuildContext context,
    required File video,
    required String folderName,
    ProgressCallback? onProgress,
  }) async {
    try {
      final upload = await CloudinaryRest.uploadVideoSigned(
        file: video,
        cloudName: ApiConstants.cloudinaryName,
        apiKey: ApiConstants.cloudinaryApiKey,
        apiSecret: ApiConstants.cloudinaryApiSecret,
        folder: folderName,
        onProgress: onProgress,
      );

      // Return the compressed MP4 delivery URL
      return Result(data: upload.publicId);
    } catch (e) {
      return Result(error: e.toString());
    }
  }

  // Upload Image or Video to AWS S3
  static Future<Result<String?>> uploadFile({
    File? photo,
    File? video,
    required String folderName,
    required PostType postType,
    String type = "png",
    String? previousKey,
    required BuildContext context,
    ProgressCallback? onProgress, // added callback parameter
  }) async {
    try {
      if (postType == PostType.image) {
        if (photo == null) {
          return Result(error: 'Photo file is required for image upload.');
        }
        final String filePath =
            "$folderName/${DateTime.now().millisecondsSinceEpoch}.$type";

        final uploadTask = Amplify.Storage.uploadFile(
          localFile: AWSFilePlatform.fromFile(photo),
          path: StoragePath.fromString(filePath),
          onProgress: (progress) {
            // Report progress via the callback if provided
            if (onProgress != null) {
              onProgress(progress.fractionCompleted);
            }
          },
        );

        final result = await uploadTask.result;

        if (previousKey != null) {
          await deleteAWSFile(previousKey, postType);
        }

        return Result(data: result.uploadedItem.path);
      } else if (postType == PostType.video) {
        if (video == null) {
          return Result(error: 'Video file is required for video upload.');
        }
        final String filePath =
            "$folderName/${DateTime.now().millisecondsSinceEpoch}.mp4";

        final uploadTask = Amplify.Storage.uploadFile(
          localFile: AWSFilePlatform.fromFile(video),
          path: StoragePath.fromString(filePath),
          onProgress: (progress) {
            if (onProgress != null) {
              onProgress(progress.fractionCompleted);
            }
          },
        );

        final result = await uploadTask.result;

        if (previousKey != null) {
          await deleteAWSFile(previousKey, postType);
        }

        return Result(data: result.uploadedItem.path);
      }
      return Result(error: "Invalid file type");
    } catch (e) {
      return Result(error: e.toString());
    }
  }

  // Delete a file from AWS S3
  static Future<String?> deleteAWSFile(String key, PostType type) async {
    try {
      await Amplify.Storage.remove(
        path: StoragePath.fromString(key),
      );

      return null;
    } on StorageException catch (e) {
      return e.message;
    }
  }
}

// Enum to represent Post Type
enum PostType { image, video, text }
