import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vuta/core/theme.dart';
import 'package:vuta/features/history/history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: items.isEmpty
          ? const Center(child: Text('No history yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
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
                    title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${item.type} • ${item.date}'),
                  ),
                );
              },
            ),
    );
  }
}
