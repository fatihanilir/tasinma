import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ads_service_mobile.dart';
import 'ad_unit.dart';

export 'ad_unit.dart';

/// Mobil: AdMob banner. Yüklenene kadar ve yüklenemezse yer kaplamaz.
class AdBannerPlaceholder extends StatefulWidget {
  final String label;
  final bool compact;
  final AdUnit unit;

  const AdBannerPlaceholder({
    super.key,
    this.label = 'Reklam',
    this.compact = false,
    this.unit = AdUnit.display,
  });

  @override
  State<AdBannerPlaceholder> createState() => _AdBannerPlaceholderState();
}

class _AdBannerPlaceholderState extends State<AdBannerPlaceholder> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    _load(MediaQuery.sizeOf(context).width);
  }

  Future<void> _load(double screenWidth) async {
    if (!await AdsService.ready || !mounted) return;

    final AdSize size;
    if (widget.unit == AdUnit.display) {
      final adaptive =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
        (screenWidth - 36).truncate(),
      );
      if (adaptive == null || !mounted) return;
      size = adaptive;
    } else {
      size = AdSize.mediumRectangle;
    }

    final ad = BannerAd(
      adUnitId: AdMobIds.banner,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null || !_loaded) return const SizedBox.shrink();
    return Center(
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
