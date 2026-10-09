/// Google AdSense birimleri (yalnızca web).
enum AdUnit {
  /// home1 — yatay display
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
}
