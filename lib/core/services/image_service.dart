import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:mymink/core/constants/api_constants.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/services/firebase_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();
  static String baseUrl = ApiConstants.awsImageBaseURL;

  /// Pick Image from Gallery or Camera
  Future<File?> pickImage(BuildContext context, String source,
      {double ratioX = 1, double ratioY = 1}) async {
    try {
      XFile? pickedFile;

      if (source == 'gallery') {
        if (!await requestGalleryPermission(context)) return null;
        pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      } else if (source == 'camera') {
        if (!await _requestCameraPermission(context)) return null;
        pickedFile = await _picker.pickImage(source: ImageSource.camera);
      }

      if (pickedFile != null) {
        return cropImage(File(pickedFile.path), ratioX, ratioY);
      }
      return null;
    } catch (e) {
      _showErrorDialog(context, 'Something went wrong. Please try again.');
      return null;
    }
  }

  /// Crop Image to Square
  Future<File?> cropImage(File imageFile, double ratioX, double ratioY) async {
    try {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: CropAspectRatio(ratioX: ratioX, ratioY: ratioY),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: AppColors.textBlack,
            toolbarWidgetColor: AppColors.white,
            hideBottomControls: true,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Request Gallery Permission
  static Future<bool> requestGalleryPermission(BuildContext context) async {
    PermissionStatus status;

    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      status = sdkInt <= 32
          ? await Permission.storage.status
          : await Permission.photos.status;
    } else {
      status = await Permission.photos.status;
    }

    if (status.isDenied) {
      status = await Permission.photos.request();
    }

    if (status.isPermanentlyDenied) {
      showPermissionDialog(context);
      return false;
    }

    return status.isGranted;
  }

  /// Request Camera Permission
  Future<bool> _requestCameraPermission(BuildContext context) async {
    PermissionStatus status = await Permission.camera.status;

    if (status.isDenied) {
      status = await Permission.camera.request();
    }

    if (status.isPermanentlyDenied) {
      showPermissionDialog(context);
      return false;
    }

    return status.isGranted;
  }

  /// Show Permission Dialog to Open Settings
  static void showPermissionDialog(BuildContext context) async {
    await Permission.photos.request();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'This app needs access to your photos and camera to upload profile images. Please enable permissions in the app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.pop(context);
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  /// Show Error Dialog
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Generate the URL for the image with transformations
  static String generateImageUrl({
    required String imagePath, // The path of the image in S3
    String? transformationType, // e.g., "fit-in", "resize"
    int? width, // Width for resizing
    int? height, // Height for resizing
    String? format, // e.g., "webp", "jpeg", etc.
    int? quality, // e.g., 80 for lossy compression
  }) {
    // Build the transformation part of the URL
    String transformation = "";

    // Add resizing transformations
    if (transformationType != null && (width != null || height != null)) {
      transformation += "$transformationType/";
      if (width != null && height != null) {
        transformation += "${width}x$height/";
      } else if (width != null) {
        transformation += "${width}x/";
      } else if (height != null) {
        transformation += "x$height/";
      }
    }

    // Add format and quality filters
    if (format != null) {
      transformation += "filters:format($format)/";
    }
    if (quality != null) {
      transformation += "filters:quality($quality)/";
    }

    // Build the complete URL
    return "$baseUrl/$transformation$imagePath";
  }

  static Future<File> convertUint8ListToFile(Uint8List editedImage) async {
    // Get the temporary directory
    final Directory tempDir = await getTemporaryDirectory();

    // Create a temporary file path
    final String tempFilePath =
        '${tempDir.path}/${const Uuid().v1().toString()}.jpg';

    // Write the Uint8List to a temporary file
    return File(tempFilePath).writeAsBytes(editedImage);
  }

  static Future<Uint8List?> generateThumbnail(String videoPath) async {
    final uint8list = await VideoThumbnail.thumbnailData(
      video: videoPath,
      imageFormat: ImageFormat.JPEG,
      maxHeight:
          600, // specify the height of the thumbnail (the width is auto-scaled)
      quality: 46,
      timeMs: 100,
    );
    return uint8list;
  }

  static Future<File?> compressAndConvertImage(
      {required File imageFile,
      CompressFormat format = CompressFormat.jpeg}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      // Change the extension to .jpg for JPEG format
      final targetPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final XFile? compressedXFile =
          await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: 46, // Lower quality for more compression
        format: format, // Use JPEG format
        keepExif: false,
      );

      if (compressedXFile != null) {
        return File(compressedXFile.path);
      }
      return null;
    } catch (e) {
      FirebaseService.logErrorToFirebase("Compress And Convert Image: $e");
      return null;
    }
  }

  static Future<File?> compressVideoSafely(File videoFile) async {
    try {
      // Must initialize logs off
      await VideoCompress.setLogLevel(0);

      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.Res1280x720Quality,
        deleteOrigin: false,
        includeAudio: true,
        frameRate: 30,
      );

      if (mediaInfo?.file == null) {
        print("Compression failed: MediaInfo is null");
        return null;
      }

      print('Compressed video path: ${mediaInfo!.file!.path}');

      return mediaInfo.file;
    } catch (e) {
      print('Error compressing video: $e');
      return null;
    } finally {
      // OPTIONAL: You can clean after uploading is 100% done
      // await VideoCompress.deleteAllCache();
    }
  }

  static Future<bool> isVideoLengthValid(
      File videoFile, BuildContext context) async {
    final controller = VideoPlayerController.file(videoFile);
    try {
      // Initialize the controller to load video metadata
      await controller.initialize();
      final duration = controller.value.duration;

      if (duration > const Duration(seconds: 300)) {
        return false;
      } else {
        return true;
      }
    } catch (e) {
      // Optionally handle errors here
      print('Error checking video duration: $e');
      return false;
    } finally {
      controller.dispose();
    }
  }
}
