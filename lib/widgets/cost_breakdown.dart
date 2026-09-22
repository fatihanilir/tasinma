import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/home_model.dart';
import '../models/cost_item.dart';
import '../utils/formatters.dart';

class CostBreakdown extends StatefulWidget {
  final HomeModel home;
  final String? warningMessage;
  final Function(CostItem)? onAddCost;
  final Function(String)? onRemoveCost;
  final Function(String, double)? onUpdateCostAmount;

  const CostBreakdown({
    super.key,
    required this.home,
    this.warningMessage,
    this.onAddCost,
    this.onRemoveCost,
    this.onUpdateCostAmount,
  });

  @override
  State<CostBreakdown> createState() => _CostBreakdownState();
}

class _CostBreakdownState extends State<CostBreakdown> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final home = widget.home;
    final isEditable = widget.onAddCost != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MALİYET KIRILIMI',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            
            // Banka giderleri uyarısı (kredi çekilecekse)
            if (home.needsLoan) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.coral.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.coral.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, 
                      color: AppColors.coral, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Kredi çekilecekse ekspertiz, sigorta ve tahsis ücreti gibi banka giderlerini de ekle.',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.coral,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            
            // Ev fiyatı
            _CostRow(
              label: 'Ev fiyatı',
              value: home.price > 0 ? Formatters.formatTL(home.price) : '—',
            ),
            
            // Alım-satım vergisi
            _CostRow(
              label: 'Alım-satım vergisi ${Formatters.formatPercent(home.taxRate)}',
              value: home.price > 0 ? Formatters.formatTL(home.tax) : '—',
            ),
            
            // Emlakçı komisyonu
            _CostRow(
              label: home.commRate == 0
                  ? 'Emlakçı (sahibinden)'
                  : 'Emlakçı komisyonu ${Formatters.formatPercent(home.commRate)}',
              value: home.price > 0 ? Formatters.formatTL(home.commission) : '—',
            ),
            
            // Döner sermaye (sadece fiyat girilmişse göster)
            if (home.hasValidInput)
              _CostRow(
                label: 'Döner sermaye',
                value: Formatters.formatTL(HomeModel.donerSermaye),
              ),
            
            // Döner sermaye - ipotek borcu (yalnızca kredi gerekiyorsa)
            if (home.needsLoan)
              _CostRow(
                label: 'Döner sermaye - ipotek borcu',
                value: Formatters.formatTL(HomeModel.donerSermaye),
              ),
            
            // Tadilat
            if (home.reno > 0)
              _CostRow(
                label: 'Tadilat',
                value: Formatters.formatTL(home.reno),
              ),
            
            // Ek maliyetler
            ...home.additionalCosts.map((cost) => _CostRow(
                  label: cost.name,
                  value: Formatters.formatTL(cost.amount),
                  onRemove: isEditable ? () => widget.onRemoveCost?.call(cost.id) : null,
                  onEdit: isEditable
                      ? () => _showEditCostDialog(cost)
                      : null,
                )),
            
            // Maliyet ekle butonu
            if (isEditable) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.goldSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isExpanded ? Icons.remove : Icons.add,
                        size: 18,
                        color: AppColors.forest,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Maliyet ekle',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.forest,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Genişletilebilir maliyet ekleme bölümü
              if (_isExpanded) ...[
                const SizedBox(height: 12),
                _QuickCostOptions(
                  onAddCost: widget.onAddCost,
                  existingCostIds: home.additionalCosts.map((c) => c.id).toSet(),
                ),
              ],
            ],
            
            const SizedBox(height: 16),
            
            // Toplam - öne çıkan tasarım
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.forest.withOpacity(0.08),
                    AppColors.forest.withOpacity(0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.forest.withOpacity(0.15),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.forest.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 20,
                      color: AppColors.forest,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOPLAM MALİYET',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.08 * 11,
                            color: AppColors.forest2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          home.price > 0 ? Formatters.formatTL(home.totalCost) : '—',
                          style: GoogleFonts.fraunces(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.forest,
                            letterSpacing: -0.02 * 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Genel uyarı
            if (widget.warningMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E6D8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  widget.warningMessage!,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFF7A3D22),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditCostDialog(CostItem cost) {
    _showAmountSheet(
      context: context,
      title: cost.name,
      initialAmount: cost.amount,
      confirmLabel: 'Kaydet',
      onConfirm: (amount) {
        widget.onUpdateCostAmount?.call(cost.id, amount);
      },
    );
  }
}

void _showAmountSheet({
  required BuildContext context,
  required String title,
  double? initialAmount,
  String confirmLabel = 'Ekle',
  required ValueChanged<double> onConfirm,
}) {
  final amountController = TextEditingController(
    text: initialAmount != null && initialAmount > 0
        ? Formatters.formatNumber(initialAmount)
        : '',
  );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFFDF8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.fraunces(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  scrollPadding: const EdgeInsets.only(bottom: 120),
                  decoration: const InputDecoration(
                    labelText: 'Tutar (TL)',
                    border: OutlineInputBorder(),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  onChanged: (_) {
                    final text = amountController.text;
                    final formatted = Formatters.formatInputValue(text);
                    if (formatted != text) {
                      amountController.value = TextEditingValue(
                        text: formatted,
                        selection:
                            TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                  },
                  onSubmitted: (_) {
                    final amount = Formatters.parseNumber(amountController.text);
                    if (amount <= 0) return;
                    onConfirm(amount);
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('İptal'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final amount =
                              Formatters.parseNumber(amountController.text);
                          if (amount <= 0) return;
                          onConfirm(amount);
                          Navigator.pop(ctx);
                        },
                        child: Text(confirmLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void _showCustomCostSheet({
  required BuildContext context,
  required void Function(String name, double amount) onConfirm,
}) {
  final nameController = TextEditingController();
  final amountController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFFDF8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Özel Maliyet Ekle',
                  style: GoogleFonts.fraunces(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Maliyet adı',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  scrollPadding: const EdgeInsets.only(bottom: 120),
                  decoration: const InputDecoration(
                    labelText: 'Tutar (TL)',
                    border: OutlineInputBorder(),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  onChanged: (_) {
                    final text = amountController.text;
                    final formatted = Formatters.formatInputValue(text);
                    if (formatted != text) {
                      amountController.value = TextEditingValue(
                        text: formatted,
                        selection:
                            TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('İptal'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameController.text.trim();
                          final amount =
                              Formatters.parseNumber(amountController.text);
                          if (name.isEmpty || amount <= 0) return;
                          onConfirm(name, amount);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Ekle'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _CostRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final VoidCallback? onRemove;
  final VoidCallback? onEdit;

  const _CostRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.onRemove,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppColors.muted,
              ),
            ),
          ),
          if (onEdit != null)
            GestureDetector(
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.goldSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: AppColors.forest,
                  ),
                ),
              ),
            ),
          if (onRemove != null)
            GestureDetector(
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.coral.withOpacity(0.8),
                ),
              ),
            ),
          Text(
            value,
            style: isTotal
                ? GoogleFonts.fraunces(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.forest,
                  )
                : GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
          ),
        ],
      ),
    );
  }
}

class _QuickCostOptions extends StatelessWidget {
  final Function(CostItem)? onAddCost;
  final Set<String> existingCostIds;

  const _QuickCostOptions({
    required this.onAddCost,
    required this.existingCostIds,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HIZLI SEÇENEKLER',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1 * 11,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CostTemplates.quickOptions.map((template) {
            final isAdded = existingCostIds.contains(template.id);
            return GestureDetector(
              onTap: isAdded
                  ? null
                  : () => _showAmountDialog(context, template),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isAdded ? AppColors.forest : Colors.white,
                  border: Border.all(
                    color: isAdded ? AppColors.forest : AppColors.line,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isAdded)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.check, size: 14, color: Colors.white),
                      ),
                    Text(
                      template.name,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isAdded ? Colors.white : AppColors.forest,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Diğer (özel maliyet)
        GestureDetector(
          onTap: () => _showCustomCostDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 16, color: AppColors.forest2),
                const SizedBox(width: 6),
                Text(
                  'Diğer (özel maliyet)',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.forest2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAmountDialog(BuildContext context, CostTemplate template) {
    _showAmountSheet(
      context: context,
      title: template.name,
      onConfirm: (amount) {
        onAddCost?.call(template.toCostItem(amount: amount));
      },
    );
  }

  void _showCustomCostDialog(BuildContext context) {
    _showCustomCostSheet(
      context: context,
      onConfirm: (name, amount) {
        final customId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
        onAddCost?.call(CostItem(
          id: customId,
          name: name,
          amount: amount,
          category: CostCategory.other,
        ));
      },
    );
  }
}

