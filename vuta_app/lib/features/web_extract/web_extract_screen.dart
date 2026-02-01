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
    try {
      final raw = await _controller.runJavaScriptReturningResult(
        """
(() => {
  const meta = document.querySelector('meta[property="og:video"], meta[property="og:video:url"], meta[property="og:video:secure_url"]');
  if (meta && meta.content) return meta.content;
  const v = document.querySelector('video');
  if (v) return (v.currentSrc || v.src || '');
  return '';
})()
""",
      );

      final extracted = raw.toString().replaceAll('"', '').trim();
      if (!mounted) return;

      if (extracted.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No direct media URL found yet. Try logging in, opening the reel/video, then tap Extract again.')),
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
        SnackBar(content: Text('Extract failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login & Extract'),
        actions: [
          TextButton(
            onPressed: _extract,
            child: const Text('EXTRACT'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(),
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
