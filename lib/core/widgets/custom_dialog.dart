import 'package:flutter/material.dart';

import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/services/firebase_service.dart';

class CustomDialog {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    // If title is "ERROR", log it to Firebase
    if (title.toUpperCase() == "ERROR") {
      await FirebaseService.logErrorToFirebase(message);
    }

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text(title),
          content: Text(
            message,
            style: const TextStyle(color: AppColors.textGrey),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textBlack,
                foregroundColor: AppColors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Ok"),
            ),
          ],
        );
      },
    );
  }
}
