import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vuta/core/theme.dart';
import 'package:vuta/features/downloads/downloads_provider.dart';
import 'package:vuta/services/ads_service.dart';
import 'package:vuta/widgets/ad_banner.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
      ),
      body: Column(
        children: [
          Expanded(
            child: downloads.isEmpty
                ? const Center(
                    child: Text('No downloads yet.'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: downloads.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = downloads[index];
                      final subtitle = switch (item.status) {
                        DownloadStatus.queued => 'Queued',
                        DownloadStatus.downloading =>
                          'Downloading ${(item.progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                        DownloadStatus.completed => 'Saved to Downloads/VUTA',
                        DownloadStatus.failed => 'Failed',
                      };

                      return Container(
                        decoration: BoxDecoration(
                          color: VutaTheme.glassWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: VutaTheme.glassBorder),
                        ),
                        child: ListTile(
                          title: Text(item.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text(subtitle),
                              if (item.status == DownloadStatus.downloading) ...[
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: item.progress.clamp(0, 1),
                                  color: VutaTheme.electricSavannah,
                                  backgroundColor: Colors.white12,
                                ),
                              ],
                              if (item.status == DownloadStatus.failed && item.error != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  item.error!,
                                  style: const TextStyle(color: Colors.redAccent),
                                ),
                              ],
                              if (item.status == DownloadStatus.completed && item.savedUri != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  item.savedUri!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                          trailing: item.status == DownloadStatus.failed
                              ? IconButton(
                                  onPressed: () => ref.read(downloadsProvider.notifier).retry(item.id),
                                  icon: const Icon(Icons.refresh_rounded),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          Center(
            child: AdBanner(
              adUnitId: AdsService.bannerHomeEuropeUnitId,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
