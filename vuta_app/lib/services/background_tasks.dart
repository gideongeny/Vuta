import 'package:workmanager/workmanager.dart';
import 'package:vuta/core/download_engine.dart';
import 'package:media_store_plus/media_store_plus.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    switch (taskName) {
      case 'night_download':
        final url = inputData?['url'];
        final fileName = inputData?['fileName'];
        if (url != null && fileName != null) {
          await MediaStore.ensureInitialized();
          MediaStore.appFolder = 'VUTA';
          await DownloadEngine.startDownload(DownloadTask(
            url: url,
            fileName: fileName,
          ));
        }
        break;
    }
    return Future.value(true);
  });
}

class BackgroundTaskService {
  static void init() {
    Workmanager().initialize(
      callbackDispatcher,
    );
  }

  static void scheduleNightDownload(String url, String fileName) {
    Workmanager().registerOneOffTask(
      'night_download_${DateTime.now().millisecondsSinceEpoch}',
      'night_download',
      inputData: {
        'url': url,
        'fileName': fileName,
      },
      constraints: Constraints(
        networkType: NetworkType.unmetered,
        requiresCharging: true,
      ),
    );
  }
}
