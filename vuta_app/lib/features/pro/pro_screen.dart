import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:vuta/core/theme.dart';
import 'package:vuta/features/pro/pro_provider.dart';
import 'package:vuta/services/billing_service.dart';

import 'dart:async';

class ProScreen extends ConsumerStatefulWidget {
  const ProScreen({super.key});

  @override
  ConsumerState<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends ConsumerState<ProScreen> {
  bool _loading = true;
  bool _available = false;
  String? _error;
  List<ProductDetails> _products = const [];

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  @override
  void initState() {
    super.initState();
    _initBilling();
    _purchaseSub = InAppPurchase.instance.purchaseStream.listen(_handlePurchases);
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    _purchaseSub = null;
    super.dispose();
  }

  Future<void> _initBilling() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final available = await BillingService.instance.isAvailable();
      if (!mounted) return;
      _available = available;
      if (!available) {
        setState(() {
          _loading = false;
          _error = 'Billing is not available on this device.';
        });
        return;
      }

      final products = await BillingService.instance.getProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        await ref.read(proProvider.notifier).setPro(true);
      }

      if (purchase.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchase);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(proProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pro Features'),
        actions: [
          TextButton(
            onPressed: _loading
                ? null
                : () async {
                    await BillingService.instance.restore();
                  },
            child: const Text('Restore'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: VutaTheme.glassWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: VutaTheme.glassBorder),
              ),
              child: Text(
                isPro
                    ? 'Pro is unlocked on this device.'
                    : 'Upgrade to Pro to unlock premium features.\n\nIf products do not show up, you must create subscriptions in Play Console and use the same product IDs as in the app.',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pro unlocks',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('- WhatsApp Status Saver'),
            const Text('- Night Queue (scheduled downloads)'),
            const SizedBox(height: 16),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (!_loading && _error != null) Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            if (!_loading && _error == null && !_available)
              const Text('Billing not available.'),
            if (!_loading && _error == null && _available)
              Expanded(
                child: _products.isEmpty
                    ? const Center(
                        child: Text('No subscription products found. Add them in Play Console then try again.'),
                      )
                    : ListView.separated(
                        itemCount: _products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final p = _products[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: VutaTheme.glassWhite,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: VutaTheme.glassBorder),
                            ),
                            child: ListTile(
                              title: Text(p.title),
                              subtitle: Text(p.description),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: VutaTheme.electricSavannah,
                                  foregroundColor: VutaTheme.deepOnyx,
                                ),
                                onPressed: () async {
                                  await BillingService.instance.buy(p);
                                },
                                child: Text(p.price),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            if (isPro) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await ref.read(proProvider.notifier).setPro(false);
                  },
                  child: const Text('Reset Pro (local)'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
