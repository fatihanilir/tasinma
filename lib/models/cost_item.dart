/// Maliyet kalemi modeli
class CostItem {
  final String id;
  final String name;
  final double amount;
  final bool isDefault; // Otomatik eklenen mi?
  final bool isRequired; // Zorunlu mu? (örn: ekspertiz kredi varsa)
  final CostCategory category;

  const CostItem({
    required this.id,
    required this.name,
    required this.amount,
    this.isDefault = false,
    this.isRequired = false,
    this.category = CostCategory.other,
  });

  CostItem copyWith({
    String? id,
    String? name,
    double? amount,
    bool? isDefault,
    bool? isRequired,
    CostCategory? category,
  }) =>
      CostItem(
        id: id ?? this.id,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        isDefault: isDefault ?? this.isDefault,
        isRequired: isRequired ?? this.isRequired,
        category: category ?? this.category,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'isDefault': isDefault,
        'isRequired': isRequired,
        'category': category.name,
      };

  factory CostItem.fromJson(Map<String, dynamic> json) => CostItem(
        id: json['id'] as String,
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        isDefault: json['isDefault'] as bool? ?? false,
        isRequired: json['isRequired'] as bool? ?? false,
        category: CostCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => CostCategory.other,
        ),
      );
}

enum CostCategory {
  government, // Döner sermaye vb.
  bank, // Banka masrafları
  insurance, // Sigortalar
  utility, // Abonelikler
  moving, // Taşınma
  other, // Diğer
}

/// Hazır maliyet şablonları
class CostTemplates {
  // Döner sermaye (2026) - her zaman eklenir
  static const double donerSermaye2026 = 6681;

  // Hazır seçenekler
  static const List<CostTemplate> quickOptions = [
    CostTemplate(id: 'ekspertiz', name: 'Ekspertiz', suggestedAmount: 5000, category: CostCategory.bank),
    CostTemplate(id: 'sigorta', name: 'Sigorta', suggestedAmount: 15000, category: CostCategory.insurance),
    CostTemplate(id: 'dosya_masrafi', name: 'Dosya masrafı', suggestedAmount: 5000, category: CostCategory.bank),
    CostTemplate(id: 'tahsis_ucreti', name: 'Konut kredisi tahsis ücreti', suggestedAmount: 10000, category: CostCategory.bank),
    CostTemplate(id: 'dask', name: 'DASK', suggestedAmount: 1500, category: CostCategory.insurance),
    CostTemplate(id: 'hayat_sigortasi', name: 'Hayat sigortası', suggestedAmount: 20000, category: CostCategory.insurance),
    CostTemplate(id: 'elektrik', name: 'Elektrik aboneliği', suggestedAmount: 2000, category: CostCategory.utility),
    CostTemplate(id: 'su', name: 'Su aboneliği', suggestedAmount: 1500, category: CostCategory.utility),
    CostTemplate(id: 'dogalgaz', name: 'Doğalgaz aboneliği', suggestedAmount: 2500, category: CostCategory.utility),
    CostTemplate(id: 'tasinma', name: 'Taşınma', suggestedAmount: 50000, category: CostCategory.moving),
    CostTemplate(id: 'badana', name: 'Badana', suggestedAmount: 70000, category: CostCategory.moving),
  ];
}

class CostTemplate {
  final String id;
  final String name;
  final double suggestedAmount;
  final CostCategory category;

  const CostTemplate({
    required this.id,
    required this.name,
    required this.suggestedAmount,
    required this.category,
  });

  CostItem toCostItem({double? amount}) => CostItem(
        id: id,
        name: name,
        amount: amount ?? suggestedAmount,
        category: category,
      );
}
