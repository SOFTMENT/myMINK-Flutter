import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CommonUtils {
  // Copy to clipboard function
  static void copyToClipboard(
      BuildContext context, String email, String password) {
    final formattedString = "Email - $email\n\nPassword - $password";
    Clipboard.setData(ClipboardData(text: formattedString));

    // Show a snackbar to confirm copy
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard!')),
    );
  }

  static String countryCodeToEmoji(String countryCode) {
    return String.fromCharCode(countryCode.codeUnitAt(0) + 0x1F1E6 - 65) +
        String.fromCharCode(countryCode.codeUnitAt(1) + 0x1F1E6 - 65);
  }
}
