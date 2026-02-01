import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResolverResult {
  final String url;
  final String type;

  const ResolverResult({
    required this.url,
    required this.type,
  });
}

class ResolverService {
  ResolverService._();

  static const String _prefsKey = 'resolver_base_url_v1';

  static const String baseUrl = String.fromEnvironment(
    'RESOLVER_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const String apiKey = String.fromEnvironment(
    'RESOLVER_API_KEY',
    defaultValue: '',
  );

  static String? _cachedBaseUrl;

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 20),
      headers: {
        'content-type': 'application/json',
        'accept': 'application/json',
        if (apiKey != '') 'authorization': 'Bearer $apiKey',
      },
    ),
  );

  static Future<String> getConfiguredBaseUrl() async {
    final cached = _cachedBaseUrl;
    if (cached != null) return cached;

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    final resolved = (stored == null || stored.trim().isEmpty) ? baseUrl : stored.trim();
    _cachedBaseUrl = resolved;
    return resolved;
  }

  static Future<void> setConfiguredBaseUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value.trim().isEmpty) {
      await prefs.remove(_prefsKey);
      _cachedBaseUrl = baseUrl;
      return;
    }

    final normalized = value.trim().replaceAll(RegExp(r'/+$'), '');
    await prefs.setString(_prefsKey, normalized);
    _cachedBaseUrl = normalized;
  }

  static Future<ResolverResult?> resolvePlayableUrl({required String pageUrl}) async {
    final u = (await getConfiguredBaseUrl()).trim();
    if (u.isEmpty) return null;

    final res = await _dio.post<Map<String, dynamic>>(
      '$u/resolve',
      data: {
        'url': pageUrl,
      },
      options: Options(responseType: ResponseType.json),
    );

    final data = res.data;
    if (data == null) return null;

    final ok = data['ok'] == true;
    if (!ok) return null;

    final url = data['url'];
    final type = data['type'];
    if (url is String && url.trim().isNotEmpty) {
      return ResolverResult(
        url: url.trim(),
        type: type is String && type.trim().isNotEmpty ? type.trim() : 'unknown',
      );
    }

    return null;
  }
}
