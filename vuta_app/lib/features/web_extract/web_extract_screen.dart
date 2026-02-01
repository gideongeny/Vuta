import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  
      // Try to find video URLs in JSON-LD and structured data
      const jsonScripts = document.querySelectorAll('script[type="application/json"], script[type="application/ld+json"]');
      for (const script of jsonScripts) {
        try {
          const data = JSON.parse(script.textContent);
          const search = (obj) => {
            if (typeof obj !== 'object' || obj === null) return null;
            for (const [key, value] of Object.entries(obj)) {
              if (typeof value === 'string' && value.match(/https?:\/\/[^"\\s]+\\.(mp4|m3u8|webm|mov)/i)) {
                if (!value.startsWith('blob:')) return value;
              }
              if (typeof value === 'object') {
                const found = search(value);
                if (found) return found;
              }
            }
            return null;
          };
          const found = search(data);
          if (found) return found;
        } catch(e) {}
      }
      
      // Last resort: check for blob URLs
      const v = document.querySelector('video');
      if (v && (v.currentSrc || v.src)) {
        const src = (v.currentSrc || v.src || '').trim();
        if (src.startsWith('blob:')) {
          // For blob URLs, try to get the actual source
          // This works if the video has already loaded
          try {
            const canvas = document.createElement('canvas');
            canvas.width = v.videoWidth || 1;
            canvas.height = v.videoHeight || 1;
            const ctx = canvas.getContext('2d');
            ctx.drawImage(v, 0, 0);
            // Can't extract blob URL directly, but we can try to find it in page
            return src; // Return blob URL - app will handle it
          } catch(e) {
            return src;
          }
        }
        return src;
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

      // Handle blob URLs - try to extract from page source or network
      if (extracted.startsWith('blob:')) {
        setState(() => _lastExtracted = extracted);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Blob URL detected. Trying alternative extraction methods...'),
            duration: Duration(seconds: 3),
          ),
        );

        // Wait a bit more and try again with enhanced extraction
        await Future.delayed(const Duration(milliseconds: 2000));

        // Try enhanced extraction that monitors network requests
        try {
          final enhancedExtraction = await _controller.runJavaScriptReturningResult(
            """
            (() => {
              // Try to find video in page data/scripts more aggressively
              const scripts = document.querySelectorAll('script[type="application/json"], script[type="application/ld+json"]');
              for (const script of scripts) {
                try {
                  const data = JSON.parse(script.textContent);
                  const search = (obj) => {
                    if (typeof obj !== 'object' || obj === null) return null;
                    for (const [key, value] of Object.entries(obj)) {
                      if (typeof value === 'string' && (value.includes('.mp4') || value.includes('video'))) {
                        if (value.startsWith('http') && !value.startsWith('blob:')) {
                          return value;
                        }
                      }
                      if (typeof value === 'object') {
                        const found = search(value);
                        if (found) return found;
                      }
                    }
                    return null;
                  };
                  const found = search(data);
                  if (found) return found;
                } catch(e) {}
              }
              
              // Try all video sources again after waiting
              const videos = document.querySelectorAll('video');
              for (const v of videos) {
                if (v.networkState === 2) { // NETWORK_LOADED
                  const src = v.currentSrc || v.src;
                  if (src && !src.startsWith('blob:')) return src;
                }
              }
              
              return '';
            })()
            """,
          );

          final enhanced = enhancedExtraction.toString().replaceAll('"', '').trim();
          if (enhanced.isNotEmpty && !enhanced.startsWith('blob:')) {
            setState(() => _lastExtracted = enhanced);
            Navigator.of(context).pop(enhanced);
            return;
          }
        } catch (e) {
          // Continue to show user-friendly message
        }

        // If still blob URL, show helpful message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This video uses a protected stream (blob URL).\n'
              'Try:\n'
              '1. Wait for video to fully load\n'
              '2. Tap Extract again\n'
              '3. Or use the share button on the original post to get a direct link',
            ),
            duration: Duration(seconds: 6),
          ),
        );
        return;
      }

      setState(() => _lastExtracted = extracted);
      Navigator.of(context).pop(extracted);
    } catch (e) {
      if (!mounted) return;
      
      // Extract error message, removing "Exception: " prefix if present
      String errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('Extract failed: ', '');
      
      // Show user-friendly error dialog for timeout/connection errors
      if (errorMessage.toLowerCase().contains('timeout') || 
          errorMessage.toLowerCase().contains('connection')) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Connection Timeout'),
            content: Text(
              errorMessage + '\n\n'
              'Possible solutions:\n'
              '• Check if resolver backend is running\n'
              '• Verify resolver URL in Settings\n'
              '• Try again - the backend may need more time\n'
              '• For blob URLs, resolver backend is required',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close error dialog
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ResolverSettingsScreen(),
                    ),
                  );
                },
                child: const Text('Check Settings'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Extract failed: $errorMessage'),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () {},
            ),
          ),
        );
      }
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
