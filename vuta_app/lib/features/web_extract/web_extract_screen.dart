import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:vuta/services/resolver_service.dart';

class WebExtractScreen extends StatefulWidget {
  final String initialUrl;

  const WebExtractScreen({
    super.key,
    required this.initialUrl,
  });

  @override
  State<WebExtractScreen> createState() => _WebExtractScreenState();
}

class _WebExtractScreenState extends State<WebExtractScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _extracting = false;
  String? _lastExtracted;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            setState(() {
              _loading = true;
            });
          },
          onPageFinished: (_) {
            setState(() {
              _loading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  Future<void> _extract() async {
    if (_extracting) return; // Prevent multiple simultaneous extractions
    
    setState(() => _extracting = true);
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Extracting video URL... Please wait.')),
        );
      }

      // Wait a bit for page to fully load and video to initialize
      await Future.delayed(const Duration(milliseconds: 1500));

      // Try to trigger video loading if present
      await _controller.runJavaScript('''
        (() => {
          const videos = document.querySelectorAll('video');
          videos.forEach(v => {
            try {
              if (v.paused) {
                v.muted = true;
                v.play().catch(() => {});
              }
            } catch(e) {}
          });
        })();
      ''');

      // Wait a bit more for video sources to load
      await Future.delayed(const Duration(milliseconds: 1000));

      // Enhanced extraction JavaScript
      final raw = await _controller.runJavaScriptReturningResult(
        """
(() => {
  // Try meta tags first
  const metaTags = [
    'og:video',
    'og:video:url',
    'og:video:secure_url',
    'twitter:player:stream',
    'video:url'
  ];
  
  for (const prop of metaTags) {
    const meta = document.querySelector('meta[property="' + prop + '"], meta[name="' + prop + '"]');
    if (meta && meta.content && meta.content.trim() && !meta.content.startsWith('blob:')) {
      return meta.content.trim();
    }
  }
  
  // Try video elements
  const videos = document.querySelectorAll('video');
  for (const v of videos) {
    // Check currentSrc first (most reliable)
    if (v.currentSrc && v.currentSrc.trim() && !v.currentSrc.startsWith('blob:')) {
      return v.currentSrc.trim();
    }
    
    // Check src attribute
    if (v.src && v.src.trim() && !v.src.startsWith('blob:')) {
      return v.src.trim();
    }
    
    // Check source elements inside video
    const sources = v.querySelectorAll('source');
    for (const s of sources) {
      if (s.src && s.src.trim() && !s.src.startsWith('blob:')) {
        return s.src.trim();
      }
    }
  }
  
  // Try to find video URLs in page source (for embedded players)
  const scripts = document.querySelectorAll('script');
  for (const script of scripts) {
    const content = script.textContent || script.innerHTML || '';
    const matches = content.match(/https?:\\/\\/[^"\\s]+\.(mp4|m3u8|mov|webm|mkv)/gi);
    if (matches && matches.length > 0) {
      return matches[0];
    }
  }
  
  // Last resort: check for blob URLs (will need resolver)
  const v = document.querySelector('video');
  if (v && (v.currentSrc || v.src)) {
    return (v.currentSrc || v.src || '').trim();
  }
  
  return '';
})()
""",
      );

      final extracted = raw.toString().replaceAll('"', '').trim();
      if (!mounted) return;

      if (extracted.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No video URL found. Make sure:\n1. You are logged in\n2. The video is playing\n3. Try tapping Extract again after the video loads'),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }

      if (extracted.startsWith('blob:')) {
        setState(() => _lastExtracted = extracted);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resolving stream…')),
        );

        final currentUrl = await _controller.currentUrl();
        final result = await ResolverService.resolvePlayableUrl(
          pageUrl: (currentUrl == null || currentUrl.trim().isEmpty) ? widget.initialUrl : currentUrl,
        );

        if (!mounted) return;

        if (result == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not resolve stream. Make sure the resolver backend is running and accessible.')),
          );
          return;
        }

        if (result.type.toLowerCase() == 'm3u8' || result.url.toLowerCase().contains('.m3u8')) {
          setState(() => _lastExtracted = result.url);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Resolved an HLS stream (m3u8). This app currently downloads direct files (mp4).')),
          );
          return;
        }

        setState(() => _lastExtracted = result.url);
        Navigator.of(context).pop(result.url);
        return;
      }

      setState(() => _lastExtracted = extracted);
      Navigator.of(context).pop(extracted);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Extract failed: $e'),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _extracting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login & Extract'),
        actions: [
          TextButton(
            onPressed: _extracting ? null : _extract,
            child: _extracting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('EXTRACT'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loading || _extracting) const LinearProgressIndicator(),
          Expanded(
            child: WebViewWidget(
              controller: _controller,
            ),
          ),
          if (_lastExtracted != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _lastExtracted!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
