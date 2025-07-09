import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  /// Request a list of permissions and return true if all are granted.
  static Future<bool> requestPermissions({
    required BuildContext context,
    required List<Permission> permissions,
    String rationaleTitle = 'Permissions Required',
    String rationaleMessage =
        'This feature requires certain permissions to function properly.',
  }) async {
    final statuses = await permissions.request();

    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (allGranted) return true;

    // Check for permanently denied
    if (statuses.values.any((status) => status.isPermanentlyDenied)) {
      await _showSettingsDialog(context, rationaleTitle, rationaleMessage);
      return false;
    }

    // If any denied (but not permanently)
    if (statuses.values.any((status) => status.isDenied)) {
      await _showDeniedDialog(context, rationaleTitle, rationaleMessage);
      return false;
    }

    return false;
  }

  static Future<void> _showSettingsDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(
          '$message\n\nSome permissions are permanently denied. Please enable them from app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
            child: const Text('Open Settings'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  static Future<void> _showDeniedDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(
          '$message\n\nPlease grant permissions to proceed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
