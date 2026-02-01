import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestStoragePermission() async {
    var status = await Permission.storage.request();
    if (status.isGranted) return true;
    
    // For Android 13+ (API 33+)
    if (await Permission.photos.request().isGranted || 
        await Permission.videos.request().isGranted) {
      return true;
    }
    return false;
  }

  static Future<bool> requestNotificationPermission() async {
    return await Permission.notification.request().isGranted;
  }
}
