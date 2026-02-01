import 'package:dio/dio.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';

class DownloadTask {
  final String url;
  final String fileName;
  final String? mimeType;

  DownloadTask({
    required this.url,
    required this.fileName,
    this.mimeType,
  });
}

class DownloadEngine {
  static Future<SaveInfo?> startDownload(
    DownloadTask task, {
    void Function(double progress)? onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final tempPath = '${tempDir.path}/${task.fileName}';

    final dio = Dio();
    await dio.download(
      task.url,
      tempPath,
      onReceiveProgress: (received, total) {
        if (total <= 0) return;
        onProgress?.call(received / total);
      },
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        validateStatus: (status) => status != null && status >= 200 && status < 400,
        headers: task.mimeType != null ? {'accept': task.mimeType} : null,
      ),
    );

    await MediaStore.ensureInitialized();
    if (MediaStore.appFolder.isEmpty) {
      MediaStore.appFolder = 'VUTA';
    }
    final store = MediaStore();
    return store.saveFile(
      tempFilePath: tempPath,
      dirType: DirType.download,
      dirName: DirName.download,
      relativePath: null,
    );
  }
}
