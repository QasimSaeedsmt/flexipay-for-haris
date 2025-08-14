import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dialog_utils.dart';
import 'package:flexipay/string_resources.dart';

class PermissionUtils {
  static Future<bool> requestPermission(
      Permission permissionType,
      BuildContext? context,
      ) async {
    PermissionStatus status = await permissionType.status;

    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      if (context != null) {
        DialogUtils.showAppSettingsDialog(context);
      }
      return false;
    } else {
      final PermissionStatus newStatus = await permissionType.request();
      return newStatus.isGranted;
    }
  }
}
