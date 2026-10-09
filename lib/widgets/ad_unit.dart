/// Google AdSense birimleri (yalnızca web).
///
/// Yerleşim rehberi:
/// - [display]     → Dar / sticky bar (Kaydet üstü)
/// - [inArticle]   → İçerik arası (kırılım altı, kartlar arası, karşılaştır orta)
/// - [multiplex]   → Geniş alan (boş liste, karşılaştırma sonu)
enum AdUnit {
  /// home1 — yatay display banner
  display(
    slot: '7727699704',
    format: 'horizontal',
    layout: null,
  ),

  /// In-article — akış içi fluid
  inArticle(
    slot: '9925564196',
    format: 'fluid',
    layout: 'in-article',
  ),

  /// Multiplex / autorelaxed — ilgili içerik grid
  multiplex(
    slot: '2391612541',
    format: 'autorelaxed',
    layout: null,
  );

  const AdUnit({
    required this.slot,
    required this.format,
    required this.layout,
  });

  static const client = 'ca-pub-8974319907510791';

  final String slot;
  final String format;
  final String? layout;

  /// Flutter tarafındaki minimum yükseklik (px)
  double get minHeight {
    switch (this) {
      case AdUnit.display:
        return 90;
      case AdUnit.inArticle:
        return 120;
      case AdUnit.multiplex:
        return 280;
    }
  }
}
