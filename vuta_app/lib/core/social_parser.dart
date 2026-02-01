import 'package:dio/dio.dart';
import 'dart:convert';

class SocialParser {
  static final RegExp _instaRegex = RegExp(r'(?:https?:\/\/)?(?:www\.)?instagram\.com\/(?:p|reels|reel|tv)\/([^\/?#&]+)');
  static final RegExp _fbRegex = RegExp(
    r'(?:https?:\/\/)?(?:www\.|m\.|mobile\.|touch\.)?(?:facebook\.com|fb\.watch)\/(.+)',
  );

  static String? parseInstagram(String url) {
    final m = _instaRegex.firstMatch(url);
    return m?.group(1);
  }

  static String? parseFacebook(String url) {
    final m = _fbRegex.firstMatch(url);
    return m?.group(1);
  }

  static String _unwrapFacebookRedirect(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    if (uri.host == 'l.facebook.com') {
      final u = uri.queryParameters['u'];
      if (u != null && u.isNotEmpty) {
        return Uri.decodeFull(u);
      }
    }
    return url;
  }

  static bool _isFacebookUrl(String url) {
    final unwrapped = _unwrapFacebookRedirect(url);
    final uri = Uri.tryParse(unwrapped);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    if (host == 'fb.watch') return true;
    if (host.endsWith('facebook.com')) return true;
    return _fbRegex.hasMatch(unwrapped);
  }

  static String _normalizeFacebookUrl(String url) {
    final unwrapped = _unwrapFacebookRedirect(url);
    final uri = Uri.tryParse(unwrapped);
    if (uri == null) return unwrapped;

    // Normalize common hosts (m./mobile/touch) to www.
    final host = uri.host.toLowerCase();
    final normalizedHost = host.endsWith('facebook.com') ? 'www.facebook.com' : host;

    // Facebook watch links can be like /watch/?v=123
    if (normalizedHost.endsWith('facebook.com') && uri.path == '/watch') {
      final v = uri.queryParameters['v'];
      if (v != null && v.isNotEmpty) {
        return Uri(
          scheme: uri.scheme.isEmpty ? 'https' : uri.scheme,
          host: normalizedHost,
          path: '/watch',
          queryParameters: {'v': v},
        ).toString();
      }
    }

    return uri.replace(
      scheme: uri.scheme.isEmpty ? 'https' : uri.scheme,
      host: normalizedHost,
    ).toString();
  }

  static bool isDirectMediaUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  static Future<String?> getDownloadUrl(String url) async {
    if (isDirectMediaUrl(url)) {
      return url;
    }
    final instaNormalized = await _normalizeInstagramUrl(url);
    if (_instaRegex.hasMatch(instaNormalized)) {
      return _parseInstagram(instaNormalized);
    } else if (_isFacebookUrl(url)) {
      return _parseFacebook(_normalizeFacebookUrl(url));
    }
    return null;
  }

  static Future<String> _normalizeInstagramUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    final host = uri.host.toLowerCase();
    if (!host.endsWith('instagram.com')) return url;

    // Many share links redirect to /reel/ or /p/. Follow redirects once.
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'share') {
      try {
        final dio = Dio(
          BaseOptions(
            headers: {
              'user-agent': 'Mozilla/5.0',
              'accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            },
            followRedirects: true,
            validateStatus: (status) => status != null && status >= 200 && status < 400,
          ),
        );
        final res = await dio.get<String>(url, options: Options(responseType: ResponseType.plain));
        return res.realUri.toString();
      } catch (_) {
        return url;
      }
    }

    return url;
  }

  static Future<String?> _parseInstagram(String url) async {
    try {
      final cleanUrl = url.split('?').first;
      final endpoint = '$cleanUrl?__a=1&__d=dis';
      final dio = Dio(
        BaseOptions(
          headers: {
            'user-agent': 'Mozilla/5.0',
            'accept': 'application/json,text/plain,*/*',
          },
          followRedirects: true,
          validateStatus: (status) => status != null && status >= 200 && status < 400,
        ),
      );
      final res = await dio.get(endpoint);
      final data = res.data;

      dynamic decoded;
      if (data is String) {
        decoded = jsonDecode(data);
      } else {
        decoded = data;
      }

      String? found;
      void walk(dynamic node) {
        if (found != null) return;
        if (node is Map) {
          if (node['video_url'] is String) {
            found = node['video_url'] as String;
            return;
          }
          if (node['display_url'] is String) {
            found = node['display_url'] as String;
            return;
          }
          for (final v in node.values) {
            walk(v);
          }
        } else if (node is List) {
          for (final v in node) {
            walk(v);
          }
        }
      }

      walk(decoded);
      return found;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> _parseFacebook(String url) async {
    try {
      final dio = Dio(
        BaseOptions(
          headers: {
            'user-agent': 'Mozilla/5.0',
            'accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          },
          followRedirects: true,
          validateStatus: (status) => status != null && status >= 200 && status < 400,
        ),
      );
      final res = await dio.get<String>(url, options: Options(responseType: ResponseType.plain));
      final body = res.data ?? '';

      String? raw;

      // Common JSON fields inside HTML
      raw ??= RegExp(r'\"playable_url_quality_hd\":\"(.*?)\"').firstMatch(body)?.group(1);
      raw ??= RegExp(r'\"playable_url\":\"(.*?)\"').firstMatch(body)?.group(1);

      // Sometimes the HTML contains sd_src/hd_src
      raw ??= RegExp(r'\"hd_src\":\"(.*?)\"').firstMatch(body)?.group(1);
      raw ??= RegExp(r'\"sd_src\":\"(.*?)\"').firstMatch(body)?.group(1);

      // OpenGraph meta tags
      raw ??= RegExp(r'<meta\s+property=\"og:video\"\s+content=\"(.*?)\"', caseSensitive: false)
          .firstMatch(body)
          ?.group(1);
      raw ??= RegExp(r'<meta\s+property=\"og:video:url\"\s+content=\"(.*?)\"', caseSensitive: false)
          .firstMatch(body)
          ?.group(1);

      if (raw == null || raw.isEmpty) return null;

      // Unescape FB encoding
      return raw
          .replaceAll(r'\\/', '/')
          .replaceAll(r'\\u0025', '%')
          .replaceAll(r'\\u0026', '&')
          .replaceAll(r'\\u003D', '=')
          .replaceAll(r'\\u003C', '<')
          .replaceAll(r'\\u003E', '>')
          .replaceAll(r'\\\\', '\\');
    } catch (e) {
      return null;
    }
  }

  static bool isLinkSupported(String url) {
    return isDirectMediaUrl(url) || _instaRegex.hasMatch(url) || _isFacebookUrl(url);
  }
}
