import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'permission_utils.dart';

class DialogUtils {
  static void showAppSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Permission Required"),
        content: Text("Please enable SMS permission in app settings."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettingsManually(context);
            },
            child: Text("Open Settings"),
          ),
        ],
      ),
    );
  }
  static Future<void> openAppSettingsManually(BuildContext context) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await openAppSettings(); // From permission_handler package
    }
  }
  static void showInfoDialog(
      BuildContext context, {
        required String title,
        required String message,
      }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }
}
