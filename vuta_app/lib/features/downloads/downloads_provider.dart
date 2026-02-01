import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vuta/core/download_engine.dart';
import 'package:vuta/features/history/history_provider.dart';

enum DownloadStatus {
  queued,
  downloading,
  completed,
  failed,
}

class DownloadItem {
  final String id;
  final String sourceUrl;
  final String fileName;
  final DownloadStatus status;
  final double progress;
  final String? savedUri;
  final String? error;
  final DateTime createdAt;

  const DownloadItem({
    required this.id,
    required this.sourceUrl,
    required this.fileName,
    required this.status,
    required this.progress,
    required this.createdAt,
    this.savedUri,
    this.error,
  });

  DownloadItem copyWith({
    DownloadStatus? status,
    double? progress,
    String? savedUri,
    String? error,
  }) {
    return DownloadItem(
      id: id,
      sourceUrl: sourceUrl,
      fileName: fileName,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      savedUri: savedUri ?? this.savedUri,
      error: error ?? this.error,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceUrl': sourceUrl,
      'fileName': fileName,
      'status': status.name,
      'progress': progress,
      'savedUri': savedUri,
      'error': error,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static DownloadItem fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      id: json['id'] as String? ?? '',
      sourceUrl: json['sourceUrl'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      status: DownloadStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? DownloadStatus.queued.name),
        orElse: () => DownloadStatus.queued,
      ),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      savedUri: json['savedUri'] as String?,
      error: json['error'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

final downloadsProvider = NotifierProvider<DownloadsNotifier, List<DownloadItem>>(DownloadsNotifier.new);

class DownloadsNotifier extends Notifier<List<DownloadItem>> {
  static const _prefsKey = 'downloads_v1';

  @override
  List<DownloadItem> build() {
    Future.microtask(_load);
    return const [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;

    final decoded = jsonDecode(raw);
    if (decoded is! List) return;

    state = decoded
        .whereType<Map>()
        .map((e) => DownloadItem.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList(growable: false));
    await prefs.setString(_prefsKey, encoded);
  }

  static String guessFileName(String url) {
    final uri = Uri.tryParse(url);
    final last = uri?.pathSegments.isNotEmpty == true ? uri!.pathSegments.last : '';
    final cleaned = last.split('?').first.trim();
    if (cleaned.isNotEmpty && cleaned.contains('.')) return cleaned;
    return 'vuta_${DateTime.now().millisecondsSinceEpoch}.bin';
  }

  static String guessTypeFromFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.mkv')) return 'video';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.webp')) return 'image';
    return 'file';
  }

  Future<String> enqueueAndStart({required String url, String? fileName}) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final resolvedFileName = (fileName == null || fileName.trim().isEmpty) ? guessFileName(url) : fileName.trim();

    final item = DownloadItem(
      id: id,
      sourceUrl: url,
      fileName: resolvedFileName,
      status: DownloadStatus.queued,
      progress: 0,
      createdAt: DateTime.now(),
    );

    state = [item, ...state];
    _save();

    await _start(id);
    return id;
  }

  Future<void> retry(String id) async {
    final idx = state.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    state = [
      for (final e in state)
        if (e.id == id)
          e.copyWith(status: DownloadStatus.queued, progress: 0, error: null, savedUri: null)
        else
          e
    ];
    _save();
    await _start(id);
  }

  Future<void> _start(String id) async {
    final idx = state.indexWhere((e) => e.id == id);
    if (idx < 0) return;

    final current = state[idx];

    state = [
      for (final e in state)
        if (e.id == id) e.copyWith(status: DownloadStatus.downloading, progress: 0, error: null) else e
    ];
    _save();

    try {
      await MediaStore.ensureInitialized();
      MediaStore.appFolder = 'VUTA';

      final info = await DownloadEngine.startDownload(
        DownloadTask(url: current.sourceUrl, fileName: current.fileName),
        onProgress: (p) {
          state = [
            for (final e in state)
              if (e.id == id) e.copyWith(progress: p) else e
          ];
        },
      );

      if (info == null || !info.isSuccessful) {
        state = [
          for (final e in state)
            if (e.id == id) e.copyWith(status: DownloadStatus.failed, error: 'Save failed') else e
        ];
        _save();
        return;
      }

      state = [
        for (final e in state)
          if (e.id == id)
            e.copyWith(status: DownloadStatus.completed, progress: 1.0, savedUri: info.uri.toString())
          else
            e
      ];
      _save();

      ref.read(historyProvider.notifier).add(
            DownloadHistoryItem(
              title: current.fileName,
              date: DateTime.now().toIso8601String(),
              type: guessTypeFromFileName(current.fileName),
            ),
          );
    } catch (e) {
      state = [
        for (final item in state)
          if (item.id == id) item.copyWith(status: DownloadStatus.failed, error: e.toString()) else item
      ];
      _save();
    }
  }
}
