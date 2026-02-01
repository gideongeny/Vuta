import 'dart:io';

class WhatsAppService {
  static Future<List<File>> getStatuses() async {
    // Typical path for WhatsApp Business and Personal statuses
    const String statusPath = '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses';
    final directory = Directory(statusPath);

    if (await directory.exists()) {
      return directory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.mp4') || file.path.endsWith('.jpg'))
          .toList();
    }
    return [];
  }
}
