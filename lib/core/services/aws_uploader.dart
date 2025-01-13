import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:aws_common/vm.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:mymink/core/utils/result.dart';

class AWSUploader {
  static Future<void> showProgressDialog(
      BuildContext context, String progressPercentage) {
    return showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent, // Transparent background
          elevation: 0,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black
                  .withValues(alpha: 0.75), // Semi-transparent black
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Colors.white, // White color for the spinner
                ),
                SizedBox(width: 20),
                Text(
                  'Uploading: $progressPercentage%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<bool> checkExplicitImage(String image) async {
    try {
      // Data to pass to the Cloud Function
      final data = {'image': image};

      // Call the Cloud Function
      final result = await FirebaseFunctions.instance
          .httpsCallable('checkExplicitImage')
          .call(data);

      // Parse the result
      final resultData = result.data as Map<String, dynamic>;
      if (resultData.containsKey('isExplicit')) {
        return resultData['isExplicit'] as bool;
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      print('Error calling checkExplicitImage: $e');
      return false;
    }
  }

  // Upload Image or Video to AWS S3
  static Future<Result<String?>> uploadFile({
    File? photo,
    File? video,
    required String folderName,
    required PostType postType,
    bool shouldHideProgress = false,
    String type = "jpg",
    String? previousKey,
    required BuildContext context, // Added context to show the ProgressHud
  }) async {
    try {
      if (postType == PostType.image) {
        // Image Upload
        if (photo == null) {
          return Result(error: 'Photo file is required for image upload.');
        }

        final String fileType = type == "jpg" ? "jpeg" : "png";
        final String filePath =
            "$folderName/${DateTime.now().millisecondsSinceEpoch}.$fileType";

        // Show initial ProgressHud
        if (!shouldHideProgress) {
          showProgressDialog(context, "0.0");
        }

        // Upload the image
        final uploadTask = Amplify.Storage.uploadFile(
          localFile: AWSFilePlatform.fromFile(photo),
          path: StoragePath.fromString(filePath),
          onProgress: (progress) {
            if (!shouldHideProgress) {
              final progressPercentage =
                  (progress.fractionCompleted * 100).toStringAsFixed(2);
              Navigator.of(context).pop();
              showProgressDialog(context, progressPercentage);
            }
          },
        );

        final result = await uploadTask.result;

        // Hide ProgressHud
        if (!shouldHideProgress) {
          Navigator.of(context).pop();
        }

        // Delete the previous file if needed
        if (previousKey != null) {
          await deleteAWSFile(previousKey, postType);
        }

        return Result(data: result.uploadedItem.path);
      } else if (postType == PostType.video) {
        // Video Upload
        if (video == null) {
          return Result(error: 'Video file is required for video upload.');
        }

        final String filePath =
            "$folderName/${DateTime.now().millisecondsSinceEpoch}.mov";

        // Show initial ProgressHud
        if (!shouldHideProgress) {
          showProgressDialog(context, "0.0");
        }

        // Upload the video
        final uploadTask = Amplify.Storage.uploadFile(
          localFile: AWSFilePlatform.fromFile(video),
          path: StoragePath.fromString(filePath),
          onProgress: (progress) {
            if (!shouldHideProgress) {
              final progressPercentage =
                  (progress.fractionCompleted * 100).toStringAsFixed(2);
              Navigator.of(context).pop();
              showProgressDialog(context, progressPercentage);
            }
          },
        );

        final result = await uploadTask.result;

        // Hide ProgressHud
        if (!shouldHideProgress) {
          Navigator.of(context).pop();
        }

        // Delete the previous file if needed
        if (previousKey != null) {
          await deleteAWSFile(previousKey, postType);
        }

        return Result(data: result.uploadedItem.path);
      }
      return Result(error: "Invalid file type");
    } catch (e) {
      // Hide ProgressHud if there's an error
      if (!shouldHideProgress) {
        Navigator.of(context).pop();
      }
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
enum PostType { image, video }
