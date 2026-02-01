import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vuta/services/background_tasks.dart';

class NightQueueItem {
  final String url;
  final String fileName;
  final String scheduledAt;

  const NightQueueItem({
    required this.url,
    required this.fileName,
    required this.scheduledAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'fileName': fileName,
      'scheduledAt': scheduledAt,
    };
  }

  static NightQueueItem fromJson(Map<String, dynamic> json) {
    return NightQueueItem(
      url: json['url'] as String? ?? '',
      fileName: json['fileName'] as String? ?? 'night_download.bin',
      scheduledAt: json['scheduledAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}

final nightQueueProvider = NotifierProvider<NightQueueNotifier, List<NightQueueItem>>(NightQueueNotifier.new);

class NightQueueNotifier extends Notifier<List<NightQueueItem>> {
  static const _prefsKey = 'night_queue_v1';

  @override
  List<NightQueueItem> build() {
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
        .map((e) => NightQueueItem.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList(growable: false));
    await prefs.setString(_prefsKey, encoded);
  }

  Future<void> add({required String url, required String fileName}) async {
    final item = NightQueueItem(
      url: url,
      fileName: fileName,
      scheduledAt: DateTime.now().toIso8601String(),
    );
    state = [item, ...state];
    await _save();

    BackgroundTaskService.scheduleNightDownload(url, fileName);
  }

  Future<void> clear() async {
    state = const [];
    await _save();
  }
}
