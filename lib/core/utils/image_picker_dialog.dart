import 'package:flutter/material.dart';

class ImagePickerDialog {
  static Future<String?> show(BuildContext context) async {
    return showModalBottomSheet<String>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Using Camera'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: Icon(Icons.photo),
                title: Text('From Photo Library'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              ListTile(
                leading: Icon(Icons.cancel),
                title: Text('Cancel'),
                onTap: () => Navigator.pop(context, null),
              ),
            ],
          ),
        );
      },
    );
  }
}
