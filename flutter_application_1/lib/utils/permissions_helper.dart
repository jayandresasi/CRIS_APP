import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsHelper {
  /// Request permissions needed for taking or picking images.
  /// Returns true if all required permissions were granted.
  static Future<bool> requestImagePermissions() async {
    if (kIsWeb) return true;

    try {
      if (Platform.isAndroid) {
        final cameraStatus = await Permission.camera.request();
        final photosStatus = await Permission.photos.request();

        if (photosStatus == PermissionStatus.permanentlyDenied) {
          final storageStatus = await Permission.storage.request();
          return cameraStatus.isGranted && storageStatus.isGranted;
        }
        return cameraStatus.isGranted && photosStatus.isGranted;
      } else if (Platform.isIOS) {
        final statuses = await [Permission.camera, Permission.photos].request();
        return statuses[Permission.camera]!.isGranted &&
            statuses[Permission.photos]!.isGranted;
      } else {
        return true;
      }
    } catch (e) {
      debugPrint('PermissionsHelper error: $e');
      return false;
    }
  }
}
