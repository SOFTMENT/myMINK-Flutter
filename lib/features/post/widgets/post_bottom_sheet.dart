import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/services/aws_uploader.dart';
import 'package:mymink/core/services/image_service.dart';
import 'package:mymink/core/widgets/custom_icon_button.dart';
import 'package:mymink/features/post/widgets/icon_column.dart';
import 'package:mymink/gen/assets.gen.dart';

class PostBottomSheet {
  final VoidCallback onTextSelected;
  final VoidCallback onImageSelected;
  final VoidCallback onReelSelected;
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  // Constructor to accept the callback functions
  PostBottomSheet({
    required this.onTextSelected,
    required this.onImageSelected,
    required this.onReelSelected,
  });

  static Future<void> _callPicker(
      BuildContext context, PostType postType) async {
    // Check gallery permission before launching the picker.
    bool hasGalleryPermission =
        await ImageService.requestGalleryPermission(context);
    if (!hasGalleryPermission) {
      return;
    }

    final theme = InstaAssetPicker.themeData(AppColors.primaryRed);

    await InstaAssetPicker.pickAssets(
      context,
      maxAssets: postType == PostType.video ? 1 : 4,
      requestType:
          postType == PostType.video ? RequestType.video : RequestType.image,
      pickerConfig: InstaAssetPickerConfig(
        actionsBuilder: (context, pickerTheme, height, unselectAll) {
          return [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.camera_alt, color: Colors.white),
            ),
          ];
        },
        cropDelegate:
            const InstaAssetCropDelegate(cropRatios: [1], preferredSize: 1080),
        pickerTheme: theme.copyWith(
          canvasColor: Colors.black,
          splashColor: Colors.grey,
          colorScheme: theme.colorScheme.copyWith(
            surface: Colors.black87,
          ),
          appBarTheme: theme.appBarTheme.copyWith(
            backgroundColor: Colors.black,
            titleTextStyle: Theme.of(context)
                .appBarTheme
                .titleTextStyle
                ?.copyWith(color: Colors.white),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.white,
              disabledForegroundColor: AppColors.primaryRed,
            ),
          ),
        ),
      ),
      onCompleted: (Stream<InstaAssetsExportDetails> exportDetails) async {
        List<File> files = [];
        Set<String> filePaths = {};

        await for (var exportDetail in exportDetails) {
          if (exportDetail.data.isNotEmpty) {
            for (InstaAssetsExportData exportData in exportDetail.data) {
              File? originalFile =
                  await exportData.selectedData.asset.originFile;
              if (originalFile != null &&
                  !filePaths.contains(originalFile.path)) {
                if (postType == PostType.video) {
                  if (await ImageService.isVideoLengthValid(
                      originalFile, context)) {
                    files.add(originalFile);
                    filePaths.add(originalFile.path);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Video durations should be less than 5 minutes.'),
                      ),
                    );
                    return;
                  }
                } else {
                  files.add(originalFile);
                  filePaths.add(originalFile.path);
                }
              }
            }
          }
        }

        if (files.isNotEmpty) {
          context.push(AppRoutes.addPost,
              extra: {'type': postType, 'files': files});
        }
      },
    );
  }

  // Function to show the bottom sheet
  static void showCustomBottomSheet(BuildContext context) {
    final outerContext = context; // Capture the context that is still active.
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      builder: (BuildContext bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    "Create a Post",
                    style: TextStyle(
                        color: AppColors.textBlack,
                        fontSize: 19,
                        fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  CustomIconButton(
                    icon: const Icon(
                      Icons.keyboard_arrow_down_outlined,
                      size: 36,
                    ),
                    onPressed: () {
                      Navigator.of(bottomSheetContext).pop();
                    },
                  ),
                  const SizedBox(width: 10),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Text option
                  Expanded(
                    child: IconColumn(
                      icon: Assets.images.quote.image(),
                      label: "Text",
                      color: AppColors.textGrey,
                      onTap: () {
                        print('Text selected');
                        Navigator.of(bottomSheetContext).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Image option
                  Expanded(
                    child: IconColumn(
                      icon: Assets.images.gallery.image(),
                      label: "Image",
                      color: AppColors.primaryRed,
                      onTap: () {
                        // Use the captured outerContext for _callPicker
                        Navigator.of(bottomSheetContext).pop();
                        _callPicker(outerContext, PostType.image);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Reel option
                  Expanded(
                    child: IconColumn(
                      icon: Assets.images.videoPlayWhite.image(),
                      label: "Reel",
                      color: AppColors.textBlack,
                      onTap: () {
                        Navigator.of(bottomSheetContext).pop();
                        _callPicker(outerContext, PostType.video);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
