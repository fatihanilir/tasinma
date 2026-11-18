import 'package:flutter/widgets.dart';
import 'ad_unit.dart';

export 'ad_unit.dart';

/// Reklamsız sürüm. Uygulama ekranları yayıncı içeriği taşımadığı için
/// (AdSense "içeriksiz ekran" politikası) web'de reklam gösterilmez.
class AdBannerPlaceholder extends StatelessWidget {
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
  Widget build(BuildContext context) => const SizedBox.shrink();
}
