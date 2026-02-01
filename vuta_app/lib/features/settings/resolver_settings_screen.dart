import 'package:flutter/material.dart';
import 'package:vuta/services/resolver_service.dart';

class ResolverSettingsScreen extends StatefulWidget {
  const ResolverSettingsScreen({super.key});

  @override
  State<ResolverSettingsScreen> createState() => _ResolverSettingsScreenState();
}

class _ResolverSettingsScreenState extends State<ResolverSettingsScreen> {
  final _controller = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final current = await ResolverService.getConfiguredBaseUrl();
    if (!mounted) return;
    _controller.text = current;
    setState(() {
      _loading = false;
    });
  }

  Future<void> _save() async {
    final value = _controller.text.trim();
    await ResolverService.setConfiguredBaseUrl(value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resolver URL saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolver Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Advanced: Resolver Backend (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'The app works without a backend! Leave empty for standalone mode.\n'
              'Backend is only needed for advanced cases (blob URLs, protected streams).',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              enabled: !_loading,
              decoration: const InputDecoration(
                hintText: 'Leave empty - app works standalone',
                border: OutlineInputBorder(),
                helperText: 'Optional: Only for advanced extraction cases',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: _loading
                      ? null
                      : () {
                          setState(() {
                            _controller.text = 'http://10.0.2.2:8080';
                          });
                        },
                  child: const Text('Emulator Local (10.0.2.2)'),
                ),
                OutlinedButton(
                  onPressed: _loading
                      ? null
                      : () {
                          setState(() {
                            _controller.text = 'http://localhost:8080';
                          });
                        },
                  child: const Text('Desktop Localhost'),
                ),
                OutlinedButton(
                  onPressed: _loading
                      ? null
                      : () {
                          setState(() {
                            _controller.text = '';
                          });
                        },
                  child: const Text('Reset to Default'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
