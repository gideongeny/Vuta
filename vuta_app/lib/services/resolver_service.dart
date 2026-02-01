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

  // Backend is optional - app works entirely client-side
  // No backend needed! App uses in-app WebView extraction
  static const String baseUrl = String.fromEnvironment(
    'RESOLVER_BASE_URL',
    defaultValue: '', // Empty = no backend needed, app works standalone
  );

  static const String apiKey = String.fromEnvironment(
    'RESOLVER_API_KEY',
    defaultValue: '',
  );

  static String? _cachedBaseUrl;

  static final Dio _dio = Dio(
    BaseOptions(
      // Increased timeouts to handle slow resolver backend operations
      // Backend may take 30-60s to launch browser, load page, and detect video
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 120),
      sendTimeout: const Duration(seconds: 30),
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
    // If user hasn't configured, use default (empty = no backend, app still works for direct URLs)
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

  /// Check if resolver backend is reachable
  static Future<bool> checkBackendHealth() async {
    final u = (await getConfiguredBaseUrl()).trim();
    if (u.isEmpty) return false;

    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '$u/health',
        options: Options(
          responseType: ResponseType.json,
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      return res.statusCode == 200 && (res.data?['ok'] == true);
    } catch (_) {
      return false;
    }
  }

  static Future<ResolverResult?> resolvePlayableUrl({required String pageUrl}) async {
    final u = (await getConfiguredBaseUrl()).trim();
    if (u.isEmpty) return null;

    try {
      // Create a new Dio instance with extended timeouts for this specific request
      final dio = Dio(
        BaseOptions(
          baseUrl: u,
          connectTimeout: const Duration(seconds: 90), // Even longer for slow connections
          receiveTimeout: const Duration(seconds: 180), // 3 minutes for complex pages
          sendTimeout: const Duration(seconds: 30),
          headers: {
            'content-type': 'application/json',
            'accept': 'application/json',
            if (apiKey != '') 'authorization': 'Bearer $apiKey',
          },
        ),
      );

      final res = await dio.post<Map<String, dynamic>>(
        '/resolve',
        data: {
          'url': pageUrl,
        },
        options: Options(
          responseType: ResponseType.json,
        ),
      );

      final data = res.data;
      if (data == null) return null;

      final ok = data['ok'] == true;
      if (!ok) {
        final error = data['error'] as String?;
        throw Exception(error ?? 'Resolver returned error');
      }

      final url = data['url'];
      final type = data['type'];
      if (url is String && url.trim().isNotEmpty) {
        return ResolverResult(
          url: url.trim(),
          type: type is String && type.trim().isNotEmpty ? type.trim() : 'unknown',
        );
      }

      return null;
    } on DioException catch (e) {
      // Handle specific timeout errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception(
          'Connection timeout. The resolver backend is taking too long to respond. '
          'This may happen if:\n'
          '1. The backend is not running\n'
          '2. The backend URL is incorrect\n'
          '3. The page is taking too long to load\n'
          'Try checking your resolver backend settings or wait a bit longer.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Cannot connect to resolver backend. Make sure:\n'
          '1. The backend is running\n'
          '2. The URL is correct (check Settings)\n'
          '3. Your device can reach the backend server',
        );
      }
      rethrow;
    } catch (e) {
      // Re-throw with context
      throw Exception('Resolver error: $e');
    }
  }
}
