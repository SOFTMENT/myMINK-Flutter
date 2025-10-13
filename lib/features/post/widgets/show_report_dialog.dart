import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/widgets/custom_button.dart';

Future<String> reportPost(
    {required String reason, required String postId}) async {
  try {
    final HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('reportPost');
    final response = await callable.call(<String, dynamic>{
      'reason': reason,
      'postID': postId,
    });
    if (response.data != null && response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final message = data['message'];
      if (message is String) {
        return message;
      }
    }
    return "An error occurred while submitting your report.";
  } catch (e) {
    print("Error calling cloud function: ${e.toString()}");
    return "An error occurred while submitting your report.";
  }
}

/// Shows an alert dialog with a text field for reporting a post.
Future<void> showReportDialog(BuildContext context, String postId) async {
  final TextEditingController controller = TextEditingController();

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title:
            const Text("Report", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Container(
          // Adjust the height to allow enough room for input.
          height: 100,
          child: TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.primaryRed),
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: "Enter your reason for reporting",
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.textGrey),
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(8),
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              "Cancel",
              style: TextStyle(color: AppColors.textDarkGrey),
            ),
          ),
          CustomButton(
              text: 'Submit',
              width: null,
              height: 42,
              onPressed: () async {
                final enteredText = controller.text.trim();
                if (enteredText.isNotEmpty) {
                  Navigator.of(context).pop(); // Dismiss the alert
                  // Call your report function.
                  final message =
                      await reportPost(reason: enteredText, postId: postId);
                  // Show a snackbar with the result.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                } else {
                  // If empty, show a message.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            const Text("Please enter a reason for reporting.")),
                  );
                }
              },
              backgroundColor: AppColors.textBlack),
        ],
      );
    },
  );
}
