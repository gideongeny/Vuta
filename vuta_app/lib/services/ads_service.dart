import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  AdsService._();

  static final AdsService instance = AdsService._();

  static const String bannerHomeUnitId = 'ca-app-pub-1281448884303417/7998696208';
  static const String bannerHomeEuropeUnitId = 'ca-app-pub-1281448884303417/8952685226';
  static const String interstitialUnitId = 'ca-app-pub-1281448884303417/3891930231';
  static const String nativeAdvancedUnitId = 'ca-app-pub-1281448884303417/8952685226';

  InterstitialAd? _interstitial;
  bool _loadingInterstitial = false;

  Future<void> init() async {
    await MobileAds.instance.initialize();
    await loadInterstitial();
  }

  Future<void> loadInterstitial() async {
    if (_loadingInterstitial) return;
    _loadingInterstitial = true;

    final completer = Completer<void>();

    await InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loadingInterstitial = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitial = null;
              unawaited(loadInterstitial());
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitial = null;
              unawaited(loadInterstitial());
            },
          );
          completer.complete();
        },
        onAdFailedToLoad: (error) {
          _interstitial = null;
          _loadingInterstitial = false;
          completer.complete();
        },
      ),
    );

    return completer.future;
  }

  Future<void> showInterstitialIfReady() async {
    final ad = _interstitial;
    if (ad == null) {
      unawaited(loadInterstitial());
      return;
    }
    ad.show();
    _interstitial = null;
  }
}
