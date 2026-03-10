import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionsHelper {
  /// Request permissions needed for taking or picking images.
  /// Returns true if all required permissions were granted.
  static Future<bool> requestImagePermissions() async {
    try {
      if (Platform.isAndroid) {
        final statuses = await [Permission.camera, Permission.storage].request();
        return statuses[Permission.camera]?.isGranted == true && (statuses[Permission.storage]?.isGranted == true || statuses[Permission.photos]?.isGranted == true);
      } else if (Platform.isIOS) {
        final statuses = await [Permission.camera, Permission.photos].request();
        return statuses[Permission.camera]?.isGranted == true && statuses[Permission.photos]?.isGranted == true;
      } else {
        // Other platforms: assume permissions are available
        return true;
      }
    } catch (e) {
      return false;
    }
  }
}
