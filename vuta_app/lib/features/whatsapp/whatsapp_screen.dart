import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vuta/core/theme.dart';
import 'package:vuta/features/whatsapp/whatsapp_provider.dart';

class WhatsAppScreen extends ConsumerWidget {
  const WhatsAppScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(whatsAppProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Status'),
        actions: [
          IconButton(
            onPressed: () => ref.read(whatsAppProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: VutaTheme.glassWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: VutaTheme.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'On Android 11+, WhatsApp status files are not directly accessible.\n\nTap “Grant Folder Access” and choose the WhatsApp .Statuses folder (or the folder that contains status files).',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VutaTheme.electricSavannah,
                        foregroundColor: VutaTheme.deepOnyx,
                      ),
                      onPressed: () => ref.read(whatsAppProvider.notifier).pickFolder(),
                      child: const Text('GRANT FOLDER ACCESS'),
                    ),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 12),
                    Text(state.error!, style: const TextStyle(color: Colors.redAccent)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: state.loading
                  ? const Center(child: CircularProgressIndicator())
                  : state.files.isEmpty
                      ? const Center(child: Text('No status files found yet.'))
                      : ListView.separated(
                          itemCount: state.files.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final doc = state.files[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: VutaTheme.glassWhite,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: VutaTheme.glassBorder),
                              ),
                              child: ListTile(
                                title: Text((doc.name ?? 'Unknown'), maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text(doc.fileType ?? ''),
                                trailing: IconButton(
                                  icon: const Icon(Icons.download_rounded),
                                  onPressed: () async {
                                    final info = await ref.read(whatsAppProvider.notifier).saveToDownloads(doc);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(info?.isSuccessful == true
                                              ? 'Saved to Downloads/VUTA'
                                              : 'Failed to save'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
