import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WhatsAppState {
  final bool loading;
  final String? error;
  final String? treeUri;
  final List<Document> files;

  const WhatsAppState({
    required this.loading,
    required this.files,
    this.treeUri,
    this.error,
  });

  WhatsAppState copyWith({
    bool? loading,
    String? error,
    String? treeUri,
    List<Document>? files,
  }) {
    return WhatsAppState(
      loading: loading ?? this.loading,
      error: error,
      treeUri: treeUri ?? this.treeUri,
      files: files ?? this.files,
    );
  }
}

final whatsAppProvider = NotifierProvider<WhatsAppNotifier, WhatsAppState>(WhatsAppNotifier.new);

class WhatsAppNotifier extends Notifier<WhatsAppState> {
  static const _prefsKey = 'whatsapp_status_tree_uri_v1';

  @override
  WhatsAppState build() {
    Future.microtask(_load);
    return const WhatsAppState(loading: false, files: []);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final uri = prefs.getString(_prefsKey);
    if (uri == null || uri.isEmpty) return;
    state = state.copyWith(treeUri: uri);
    await refresh();
  }

  Future<void> _saveUri(String uri) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, uri);
  }

  Future<void> pickFolder() async {
    state = state.copyWith(loading: true, error: null);
    try {
      await MediaStore.ensureInitialized();
      final store = MediaStore();
      final tree = await store.requestForAccess(initialRelativePath: null);
      if (tree == null) {
        state = state.copyWith(loading: false, error: 'Folder access not granted');
        return;
      }
      await _saveUri(tree.uriString);
      state = state.copyWith(loading: false, treeUri: tree.uriString);
      await refresh();
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    final uri = state.treeUri;
    if (uri == null || uri.isEmpty) return;

    state = state.copyWith(loading: true, error: null);
    try {
      await MediaStore.ensureInitialized();
      final store = MediaStore();
      final tree = await store.getDocumentTree(uriString: uri);
      final children = tree?.children ?? const <Document>[];
      final filtered = children.where((d) {
        final name = (d.name ?? '').toLowerCase();
        return name.endsWith('.mp4') ||
            name.endsWith('.jpg') ||
            name.endsWith('.jpeg') ||
            name.endsWith('.png') ||
            name.endsWith('.webp');
      }).toList(growable: false);

      state = state.copyWith(loading: false, files: filtered);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<SaveInfo?> saveToDownloads(Document doc) async {
    try {
      await MediaStore.ensureInitialized();
      MediaStore.appFolder = 'VUTA';
      final tempDir = await getTemporaryDirectory();
      final safeName = (doc.name == null || doc.name!.trim().isEmpty)
          ? 'whatsapp_status_${DateTime.now().millisecondsSinceEpoch}'
          : doc.name!.trim();
      final tempPath = '${tempDir.path}/$safeName';

      final store = MediaStore();
      final ok = await store.readFileUsingUri(uriString: doc.uriString, tempFilePath: tempPath);
      if (!ok) return null;

      final info = await store.saveFile(
        tempFilePath: tempPath,
        dirType: DirType.download,
        dirName: DirName.download,
        relativePath: null,
      );

      // Ensure temp is removed even if plugin doesn't.
      try {
        final f = File(tempPath);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {}

      return info;
    } catch (_) {
      return null;
    }
  }
}
