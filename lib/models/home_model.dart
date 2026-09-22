import 'package:uuid/uuid.dart';
import 'cost_item.dart';

class HomeModel {
  final String id;
  final String title;
  final String link;
  final double price;
  final double cash;
  final double reno; // Tadilat masrafı
  final double commRate;
  final double taxRate;
  final double interestRate;
  final int term1;
  final int term2;
  final List<CostItem> additionalCosts; // Ek maliyetler
  final int order;
  final DateTime savedAt;

  HomeModel({
    String? id,
    this.title = '',
    this.link = '',
    this.price = 0,
    this.cash = 0,
    this.reno = 0,
    this.commRate = 0.02,
    this.taxRate = 0.04,
    this.interestRate = 0.0305,
    this.term1 = 60,
    this.term2 = 120,
    List<CostItem>? additionalCosts,
    this.order = 0,
    DateTime? savedAt,
  })  : id = id ?? const Uuid().v4(),
        additionalCosts = additionalCosts ?? [],
        savedAt = savedAt ?? DateTime.now();

  // Döner sermaye (2026)
  static const double donerSermaye = 6681;

  // Geçerli giriş var mı? (fiyat girilmiş mi)
  bool get hasValidInput => price > 0;
  
  // Hesaplamalar
  double get tax => price * taxRate;
  double get commission => price * commRate;
  
  // Ek maliyetler toplamı
  double get additionalCostsTotal => 
      additionalCosts.fold(0.0, (sum, item) => sum + item.amount);
  
  // Temel maliyet (döner sermaye + ipotek borcu hariç - döngüsel bağımlılığı önlemek için)
  double get _baseCostWithoutDonerSermaye => 
      price + tax + commission + additionalCostsTotal + reno;
  
  // Kredi gerekli mi? (fiyat girilmiş ve nakit yetersizse)
  // Tek döner sermaye ile hesapla - kredi gerekirse ipotek borcu da eklenecek
  bool get needsLoan => hasValidInput && ((_baseCostWithoutDonerSermaye + donerSermaye) - cash) > 0;
  
  // Döner sermaye toplamı (kredi varsa ipotek borcu da eklenir)
  double get donerSermayeTotal => needsLoan ? donerSermaye * 2 : donerSermaye;
  
  // Toplam maliyet (fiyat girilmemişse döner sermaye gösterme)
  double get totalCost => hasValidInput
      ? price + tax + commission + donerSermayeTotal + additionalCostsTotal + reno
      : 0;
  
  double get loanAmount => needsLoan ? totalCost - cash : 0;
  
  // Ekspertiz kontrolü (kredi varsa zorunlu)
  bool get hasEkspertiz => additionalCosts.any((c) => c.id == 'ekspertiz');
  bool get ekspertizRequired => needsLoan && !hasEkspertiz;

  // Dinamik vade hesaplamaları
  double get paymentTerm1 => _calculateInstallment(loanAmount, interestRate, term1);
  double get paymentTerm2 => _calculateInstallment(loanAmount, interestRate, term2);
  double get totalPaymentTerm1 => paymentTerm1 * term1;
  double get totalPaymentTerm2 => paymentTerm2 * term2;

  // Geriye uyumluluk
  double get payment60 => paymentTerm1;
  double get payment120 => paymentTerm2;
  double get totalPayment60 => totalPaymentTerm1;
  double get totalPayment120 => totalPaymentTerm2;

  double _calculateInstallment(double principal, double monthlyRate, int months) {
    if (principal <= 0) return 0;
    if (monthlyRate == 0) return principal / months;
    final pow = _power(1 + monthlyRate, months);
    return principal * (monthlyRate * pow) / (pow - 1);
  }

  double _power(double base, int exponent) {
    double result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }

  // JSON serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'link': link,
        'price': price,
        'cash': cash,
        'reno': reno,
        'commRate': commRate,
        'taxRate': taxRate,
        'interestRate': interestRate,
        'term1': term1,
        'term2': term2,
        'additionalCosts': additionalCosts.map((c) => c.toJson()).toList(),
        'order': order,
        'savedAt': savedAt.millisecondsSinceEpoch,
      };

  factory HomeModel.fromJson(Map<String, dynamic> json) => HomeModel(
        id: json['id'] as String?,
        title: json['title'] as String? ?? '',
        link: json['link'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        cash: (json['cash'] as num?)?.toDouble() ?? 0,
        reno: (json['reno'] as num?)?.toDouble() ?? 0,
        commRate: (json['commRate'] ?? json['comm'] as num?)?.toDouble() ?? 0.02,
        taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.04,
        interestRate: (json['interestRate'] ?? json['rate'] as num?)?.toDouble() ?? 0.0305,
        term1: (json['term1'] as num?)?.toInt() ?? 60,
        term2: (json['term2'] as num?)?.toInt() ?? 120,
        additionalCosts: (json['additionalCosts'] as List<dynamic>?)
                ?.map((c) => CostItem.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
        order: (json['order'] as num?)?.toInt() ?? 0,
        savedAt: json['savedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['savedAt'] as int)
            : DateTime.now(),
      );

  HomeModel copyWith({
    String? id,
    String? title,
    String? link,
    double? price,
    double? cash,
    double? reno,
    double? commRate,
    double? taxRate,
    double? interestRate,
    int? term1,
    int? term2,
    List<CostItem>? additionalCosts,
    int? order,
    DateTime? savedAt,
  }) =>
      HomeModel(
        id: id ?? this.id,
        title: title ?? this.title,
        link: link ?? this.link,
        price: price ?? this.price,
        cash: cash ?? this.cash,
        reno: reno ?? this.reno,
        commRate: commRate ?? this.commRate,
        taxRate: taxRate ?? this.taxRate,
        interestRate: interestRate ?? this.interestRate,
        term1: term1 ?? this.term1,
        term2: term2 ?? this.term2,
        additionalCosts: additionalCosts ?? this.additionalCosts,
        order: order ?? this.order,
        savedAt: savedAt ?? this.savedAt,
      );

  String get displayTitle => title.isNotEmpty ? title : 'İsimsiz ev';

  /// İlan linkini tarayıcıda açılabilir hale getirir.
  String get normalizedLink {
    final trimmed = link.trim();
    if (trimmed.isEmpty) return '';
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }

  bool get hasLink => normalizedLink.isNotEmpty;
}
