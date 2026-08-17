import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config.dart';

/// Adaptive banner ad. On web (and when ads are disabled) renders nothing,
/// so development previews stay clean. Swap in real AdMob unit IDs in
/// config.dart once you have an AdMob account.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _banner;
  bool _loaded = false;

  bool get _isMobile =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  bool get _supported => !kIsWeb && _isMobile && AppConfig.adsEnabled;

  @override
  void initState() {
    super.initState();
    if (_supported) _load();
  }

  void _load() {
    final unitId = defaultTargetPlatform == TargetPlatform.iOS
        ? AppConfig.bannerAdUnitIos
        : AppConfig.bannerAdUnitAndroid;
    _banner = BannerAd(
      adUnitId: unitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _loaded = true),
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          setState(() => _loaded = false);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_supported || !_loaded || _banner == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 50,
        child: AdWidget(ad: _banner!),
      ),
    );
  }
}
