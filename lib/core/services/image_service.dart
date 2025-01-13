import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// Pick Image from Gallery or Camera
  Future<File?> pickImage(BuildContext context, String source) async {
    try {
      XFile? pickedFile;

      if (source == 'gallery') {
        if (!await _requestGalleryPermission(context)) return null;
        pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      } else if (source == 'camera') {
        if (!await _requestCameraPermission(context)) return null;
        pickedFile = await _picker.pickImage(source: ImageSource.camera);
      }

      if (pickedFile != null) {
        return cropImage(File(pickedFile.path));
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      _showErrorDialog(context, 'Something went wrong. Please try again.');
      return null;
    }
  }

  /// Crop Image to Square
  Future<File?> cropImage(File imageFile) async {
    try {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
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
      print('Error cropping image: $e');
      return null;
    }
  }

  /// Request Gallery Permission
  Future<bool> _requestGalleryPermission(BuildContext context) async {
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
      _showPermissionDialog(context);
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
      _showPermissionDialog(context);
      return false;
    }

    return status.isGranted;
  }

  /// Show Permission Dialog to Open Settings
  void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Permission Required'),
          content: Text(
            'This app needs access to your photos and camera to upload profile images. Please enable permissions in the app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.pop(context);
              },
              child: Text('Open Settings'),
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
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
