import 'package:intl/intl.dart';

class Formatters {
  static final _trFormat = NumberFormat('#,###', 'tr_TR');

  /// Sayıyı Türkçe formatlı TL olarak gösterir: 1.234.567 TL
  static String formatTL(double value) {
    return '${_trFormat.format(value.round())} TL';
  }

  /// Sayıyı Türkçe formatlı gösterir: 1.234.567
  static String formatNumber(double value) {
    return _trFormat.format(value.round());
  }

  /// String'i sayıya çevirir (Türkçe format destekli)
  /// "1.234.567" -> 1234567
  static double parseNumber(String value) {
    if (value.isEmpty) return 0;
    // Türkçe formatı temizle
    final cleaned = value
        .replaceAll('.', '') // Binlik ayracı
        .replaceAll(',', '.') // Ondalık ayracı
        .replaceAll(RegExp(r'[^\d.]'), ''); // Sadece rakam ve nokta
    return double.tryParse(cleaned) ?? 0;
  }

  /// Input alanları için formatlama
  static String formatInputValue(String value) {
    final number = parseNumber(value);
    if (number == 0) return '';
    return formatNumber(number);
  }

  /// Türkçe büyük harf: "Tadilat" -> "TADİLAT", "ışık" -> "IŞIK"
  static String upperTr(String value) =>
      value.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

  /// Yüzde formatı: 0.04 -> "%4"
  static String formatPercent(double rate) {
    final percent = rate * 100;
    if (percent == percent.roundToDouble()) {
      return '%${percent.toInt()}';
    }
    return '%${percent.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}
