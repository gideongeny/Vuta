import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

class BillingService {
  BillingService._();

  static final BillingService instance = BillingService._();

  static const Set<String> defaultProductIds = {
    'vuta_pro_monthly',
    'vuta_pro_yearly',
  };

  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _sub;

  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  Future<bool> isAvailable() => _iap.isAvailable();

  Future<List<ProductDetails>> getProducts({Set<String>? productIds}) async {
    final ids = (productIds == null || productIds.isEmpty) ? defaultProductIds : productIds;
    final response = await _iap.queryProductDetails(ids);
    return response.productDetails;
  }

  Future<void> buy(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async {
    await _iap.restorePurchases();
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
