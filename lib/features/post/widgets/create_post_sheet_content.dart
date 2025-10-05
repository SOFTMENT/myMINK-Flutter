import 'package:flutter/material.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/services/aws_uploader.dart';
import 'package:mymink/core/widgets/custom_icon_button.dart';

import 'package:mymink/features/post/widgets/icon_column.dart';
import 'package:mymink/features/post/widgets/post_bottom_sheet.dart';
import 'package:mymink/gen/assets.gen.dart';

class CreatePostSheetContent extends StatelessWidget {
  final String? businessId;
  final BuildContext outerContext;
  final bool showCloseButton;

  const CreatePostSheetContent({
    Key? key,
    required this.outerContext,
    this.businessId,
    this.showCloseButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, (showCloseButton ? 32 : 8)),
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
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (showCloseButton)
                CustomIconButton(
                  icon: const Icon(
                    Icons.keyboard_arrow_down_outlined,
                    size: 36,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              const SizedBox(width: 10),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (showCloseButton)
                Expanded(
                  child: IconColumn(
                    icon: Assets.images.quote.image(),
                    label: "Text",
                    color: AppColors.textGrey,
                    onTap: () {
                      print('Text selected');
                      if (showCloseButton) Navigator.of(context).pop();
                    },
                  ),
                ),
              if (showCloseButton) const SizedBox(width: 10),
              Expanded(
                child: IconColumn(
                  icon: Assets.images.gallery.image(),
                  label: "Image",
                  color: AppColors.primaryRed,
                  onTap: () {
                    if (showCloseButton) Navigator.of(context).pop();
                    PostBottomSheet.callPicker(
                      outerContext,
                      PostType.image,
                      businessId: businessId,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: IconColumn(
                  icon: Assets.images.videoPlayWhite.image(),
                  label: "Reel",
                  color: AppColors.textBlack,
                  onTap: () {
                    if (showCloseButton) Navigator.of(context).pop();
                    PostBottomSheet.callPicker(
                      outerContext,
                      PostType.video,
                      businessId: businessId,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Helper function to show the sheet modally
Future<T?> showCreatePostSheet<T>({
  required BuildContext context,
  String? businessId,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(15),
        topRight: Radius.circular(15),
      ),
    ),
    builder: (BuildContext bottomSheetContext) {
      return CreatePostSheetContent(
        outerContext: context,
        businessId: businessId,
        showCloseButton: true,
      );
    },
  );
}
