import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DownloadHistoryItem {
  final String title;
  final String date;
  final String type;

  DownloadHistoryItem({required this.title, required this.date, required this.type});

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date,
      'type': type,
    };
  }

  static DownloadHistoryItem fromJson(Map<String, dynamic> json) {
    return DownloadHistoryItem(
      title: json['title'] as String? ?? '',
      date: json['date'] as String? ?? '',
      type: json['type'] as String? ?? '',
    );
  }
}

final historyProvider = NotifierProvider<HistoryNotifier, List<DownloadHistoryItem>>(HistoryNotifier.new);

class HistoryNotifier extends Notifier<List<DownloadHistoryItem>> {
  static const _prefsKey = 'download_history_v1';

  @override
  List<DownloadHistoryItem> build() {
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
        .map((e) => DownloadHistoryItem.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList(growable: false));
    await prefs.setString(_prefsKey, encoded);
  }

  void add(DownloadHistoryItem item) {
    state = [item, ...state];
    _save();
  }
}
