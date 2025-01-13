import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlUtils {
  static Future<void> openURL(String urlString, BuildContext context) async {
    try {
      final uri = Uri.parse(urlString);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to open the URL. Please try again later.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
