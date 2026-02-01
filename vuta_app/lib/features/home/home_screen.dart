import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vuta/core/social_parser.dart';
import 'package:vuta/core/theme.dart';
import 'package:vuta/core/widgets/bento_card.dart';
import 'package:vuta/core/widgets/vuta_logo.dart';
import 'package:vuta/features/downloads/downloads_provider.dart';
import 'package:vuta/features/downloads/downloads_screen.dart';
import 'package:vuta/features/history/history_screen.dart';
import 'package:vuta/features/night_queue/night_queue_screen.dart';
import 'package:vuta/features/pro/pro_provider.dart';
import 'package:vuta/features/pro/pro_screen.dart';
import 'package:vuta/features/settings/resolver_settings_screen.dart';
import 'package:vuta/features/whatsapp/whatsapp_screen.dart';
import 'package:vuta/features/web_extract/web_extract_screen.dart';
import 'package:vuta/services/ads_service.dart';
import 'package:vuta/services/permission_service.dart';
import 'package:vuta/widgets/ad_banner.dart';
import 'package:vuta/widgets/native_ad_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _urlController = TextEditingController();
  bool _isWorking = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    setState(() => _urlController.text = text);
  }

  Future<void> _detectAndDownload() async {
    final input = _urlController.text.trim();
    if (input.isEmpty) return;

    setState(() => _isWorking = true);
    try {
      final allowed = await PermissionService.requestStoragePermission();
      if (!allowed) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied. Cannot save downloads.')),
        );
        return;
      }

      unawaited(AdsService.instance.showInterstitialIfReady());

      final resolved = await SocialParser.getDownloadUrl(input);
      if (resolved == null) {
        if (!mounted) return;
        final supported = SocialParser.isLinkSupported(input);
        if (!supported) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unsupported link. Try a direct media URL (mp4/jpg/png/webp).')),
          );
          return;
        }

        final extracted = await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (_) => WebExtractScreen(initialUrl: input),
          ),
        );

        if (!mounted) return;
        if (extracted == null || extracted.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No downloadable media URL found. If the page uses streams/blob URLs, a backend resolver is required.'),
            ),
          );
          return;
        }

        final fileName = DownloadsNotifier.guessFileName(extracted);
        await ref.read(downloadsProvider.notifier).enqueueAndStart(url: extracted, fileName: fileName);
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DownloadsScreen()));
        return;
      }

      final fileName = DownloadsNotifier.guessFileName(resolved);
      await ref.read(downloadsProvider.notifier).enqueueAndStart(url: resolved, fileName: fileName);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DownloadsScreen()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const VutaLogo(size: 48),
                  const SizedBox(width: 12),
                  Text(
                    'VUTA',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: VutaTheme.electricSavannah,
                          letterSpacing: 2,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ResolverSettingsScreen()),
                      );
                    },
                    icon: const Icon(Icons.settings_rounded),
                  ),
                ],
              ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
              const SizedBox(height: 8),
              Text(
                'Pull the Web to Your Pocket',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
              const SizedBox(height: 32),
              BentoCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        hintText: 'Paste social media link...',
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.paste_rounded, color: VutaTheme.electricSavannah),
                          onPressed: () {
                            _pasteFromClipboard();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VutaTheme.electricSavannah,
                          foregroundColor: VutaTheme.deepOnyx,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isWorking ? null : _detectAndDownload,
                        child: Text(
                          _isWorking ? 'WORKING...' : 'DETECT & DOWNLOAD',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildFeatureCard(
                      context,
                      title: 'Download',
                      icon: Icons.download_rounded,
                      color: VutaTheme.electricSavannah,
                      span: 1,
                    ),
                    _buildFeatureCard(
                      context,
                      title: 'WhatsApp',
                      icon: Icons.chat_bubble_outline_rounded,
                      color: Colors.greenAccent,
                      span: 1,
                    ),
                    _buildFeatureCard(
                      context,
                      title: 'History',
                      icon: Icons.history_rounded,
                      color: Colors.blueAccent,
                      span: 1,
                    ),
                    _buildFeatureCard(
                      context,
                      title: 'Night Queue',
                      icon: Icons.nightlight_round,
                      color: Colors.deepPurpleAccent,
                      span: 1,
                    ),
                    _buildFeatureCard(
                      context,
                      title: 'Pro Features',
                      icon: Icons.auto_awesome_rounded,
                      color: Colors.amberAccent,
                      span: 2,
                      isWide: true,
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.9, 0.9)),
              ),
              const SizedBox(height: 12),
              NativeAdWidget(
                adUnitId: AdsService.nativeAdvancedUnitId,
              ),
              const SizedBox(height: 12),
              Center(
                child: AdBanner(
                  adUnitId: AdsService.bannerHomeUnitId,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    int span = 1,
    bool isWide = false,
  }) {
    return BentoCard(
      onTap: () {
        final isPro = ref.read(proProvider);
        Widget screen;
        switch (title) {
          case 'Download':
            screen = const DownloadsScreen();
            break;
          case 'History':
            screen = const HistoryScreen();
            break;
          case 'Pro Features':
            screen = const ProScreen();
            break;
          case 'WhatsApp':
            screen = isPro ? const WhatsAppScreen() : const ProScreen();
            break;
          case 'Night Queue':
            screen = isPro ? const NightQueueScreen() : const ProScreen();
            break;
          default:
            screen = const DownloadsScreen();
        }

        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
