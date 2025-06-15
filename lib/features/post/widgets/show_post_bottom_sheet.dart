import 'package:flutter/material.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/services/firebase_service.dart';
import 'package:mymink/core/services/translation_service.dart';
import 'package:mymink/features/post/data/models/post_model.dart';
import 'package:mymink/features/post/widgets/show_report_dialog.dart';

// Import your assets and other necessary packages here.

/// Shows a modal bottom sheet with actions for the given [postModel].
Future<void> showPostBottomSheet(BuildContext context, PostModel postModel) {
  final currentUserUid = FirebaseService().auth.currentUser!.uid;
  final _height = 44.0;
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentUserUid == postModel.uid)
              SizedBox(
                height: _height,
                child: ListTile(
                  leading: const Icon(Icons.edit, color: Colors.black),
                  title: const Text("Edit"),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, '/editPost',
                        arguments: postModel);
                  },
                ),
              ),
            if (currentUserUid == postModel.uid)
              SizedBox(
                height: _height,
                child: ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text("Delete"),
                  onTap: () {
                    Navigator.of(context).pop();
                    // Show confirmation dialog before deletion.
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text(
                          "DELETE POST",
                          style: TextStyle(fontSize: 16),
                        ),
                        content: const Text(
                            "Are you sure you want to delete this post?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: AppColors.textDarkGrey),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(context).pop(); // dismiss dialog

                              // await AWSService.deletePost(
                              //     postID: postModel.postID ?? "");
                            },
                            child: const Text(
                              "Delete",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            if (currentUserUid != postModel.uid)
              SizedBox(
                height: _height,
                child: ListTile(
                  leading: const Icon(Icons.report, color: Colors.black),
                  title: const Text("Report"),
                  onTap: () {
                    Navigator.of(context).pop();
                    // Call your report functionality.
                    showReportDialog(context, postModel.postID ?? "");
                  },
                ),
              ),
            if (postModel.caption != null && postModel.caption!.isNotEmpty)
              SizedBox(
                height: _height,
                child: ListTile(
                  leading: const Icon(Icons.translate, color: Colors.black),
                  title: const Text("Translate"),
                  onTap: () {
                    Navigator.of(context).pop();
                    // Show a loader while translating.
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) =>
                          const Center(child: CircularProgressIndicator()),
                    );
                    TranslationService.shared
                        .translateText(text: postModel.caption!)
                        .then((translatedText) {
                      Navigator.of(context).pop(); // dismiss loader
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              "Translated: ${Uri.decodeComponent(translatedText)}"),
                        ),
                      );
                    });
                  },
                ),
              ),
          ],
        ),
      );
    },
  );
}
