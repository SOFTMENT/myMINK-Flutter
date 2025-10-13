import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/services/aws_uploader.dart';
import 'package:mymink/core/services/image_service.dart';
import 'package:mymink/features/post/widgets/custom_media_picker_page.dart';

class PostBottomSheet {
  PostBottomSheet();

  static Future<void> callPicker(
    BuildContext context,
    PostType postType, {
    String? businessId,
  }) async {
    final ok = await ImageService.requestGalleryPermission(context);
    if (!ok) return;

    final isVideo = postType == PostType.video;

    // Open custom picker (single screen with camera tile + gallery)
    final result = await Navigator.push<CustomMediaPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomMediaPickerPage(
          mode: isVideo ? PickerMode.video : PickerMode.image,
          maxCount: isVideo ? 1 : 4,
        ),
      ),
    );
    if (result == null) return;

    // Start with camera files (already concrete)
    final files = <File>[];
    files.addAll(result.cameraFiles);

    // Resolve gallery AssetEntity -> File in parallel
    if (result.assets.isNotEmpty) {
      final futures = result.assets.map((a) async {
        // Quick reject: if video and > 5 minutes, skip
        if (isVideo && a.duration > 300) return null;

        final f = await (a.file) ?? await a.originFile;
        if (f == null) return null;

        // Extra guard for video length using your helper
        if (isVideo) {
          final ok = await ImageService.isVideoLengthValid(f, context);
          if (!ok) return null;
        }
        return f;
      }).toList();

      final resolved = await Future.wait<File?>(futures, eagerError: false);
      files.addAll(resolved.whereType<File>());
    }

    if (files.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid media selected.')),
        );
      }
      return;
    }

    // Navigate with concrete files only
    if (context.mounted) {
      context.push(AppRoutes.addPost, extra: {
        'type': postType,
        'files': files,
        'businessId': businessId,
      });
    }
  }
}
