import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsHelper {
  /// Request permissions needed for taking or picking images.
  /// Returns true if all required permissions were granted.
  static Future<bool> requestImagePermissions() async {
    // permission_handler does not support web or desktop —
    // guard with kIsWeb first, then Platform checks.
    if (kIsWeb) return true;

    try {
      if (Platform.isAndroid) {
        // Android 13+ (SDK 33+) uses READ_MEDIA_IMAGES instead of storage.
        final cameraStatus = await Permission.camera.request();
        final photosStatus = await Permission.photos.request();

        // On Android < 13, Permission.photos may not exist and returns
        // permanentlyDenied — fall back to legacy storage permission.
        if (photosStatus == PermissionStatus.permanentlyDenied) {
          final storageStatus = await Permission.storage.request();
          return cameraStatus.isGranted && storageStatus.isGranted;
        }
        return cameraStatus.isGranted && photosStatus.isGranted;

      } else if (Platform.isIOS) {
        // .request() on a List<Permission> returns Map<Permission, PermissionStatus>
        // (non-nullable values) — use ! not ?. to access them.
      
      } else {
        // Linux / macOS / Windows desktop: no runtime permissions needed.
        return true;
      }
    } catch (e) {
      debugPrint('PermissionsHelper error: $e');
      return false;
    }
  }
}