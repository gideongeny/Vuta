import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vuta/core/theme.dart';
import 'package:vuta/features/night_queue/night_queue_provider.dart';

class NightQueueScreen extends ConsumerStatefulWidget {
  const NightQueueScreen({super.key});

  @override
  ConsumerState<NightQueueScreen> createState() => _NightQueueScreenState();
}

class _NightQueueScreenState extends ConsumerState<NightQueueScreen> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(nightQueueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Night Queue'),
        actions: [
          IconButton(
            onPressed: () => ref.read(nightQueueProvider.notifier).clear(),
            icon: const Icon(Icons.delete_sweep_rounded),
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
                children: [
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      hintText: 'Direct media URL (mp4/jpg/png...)',
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'File name (optional)',
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VutaTheme.electricSavannah,
                        foregroundColor: VutaTheme.deepOnyx,
                      ),
                      onPressed: () async {
                        final url = _urlController.text.trim();
                        if (url.isEmpty) return;
                        final fileName = _nameController.text.trim().isEmpty
                            ? 'night_${DateTime.now().millisecondsSinceEpoch}.bin'
                            : _nameController.text.trim();
                        await ref.read(nightQueueProvider.notifier).add(url: url, fileName: fileName);
                        _urlController.clear();
                        _nameController.clear();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Scheduled in Night Queue (requires charging + unmetered network).')),
                          );
                        }
                      },
                      child: const Text('ADD TO QUEUE'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('No queued downloads.'))
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: VutaTheme.glassWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: VutaTheme.glassBorder),
                          ),
                          child: ListTile(
                            title: Text(item.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(item.url, maxLines: 1, overflow: TextOverflow.ellipsis),
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
