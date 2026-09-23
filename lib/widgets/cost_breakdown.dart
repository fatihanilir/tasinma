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
  CostTemplate? _draftTemplate;
  bool _draftCustom = false;
  String? _editingCostId;
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey();

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _clearDraft() {
    setState(() {
      _draftTemplate = null;
      _draftCustom = false;
      _editingCostId = null;
      _amountController.clear();
      _nameController.clear();
    });
  }

  void _startTemplate(CostTemplate template) {
    setState(() {
      _isExpanded = true;
      _draftTemplate = template;
      _draftCustom = false;
      _editingCostId = null;
      _amountController.clear();
      _nameController.clear();
    });
    _scrollToForm();
  }

  void _startCustom() {
    setState(() {
      _isExpanded = true;
      _draftTemplate = null;
      _draftCustom = true;
      _editingCostId = null;
      _amountController.clear();
      _nameController.clear();
    });
    _scrollToForm();
  }

  void _startEdit(CostItem cost) {
    setState(() {
      _isExpanded = true;
      _draftTemplate = null;
      _draftCustom = false;
      _editingCostId = cost.id;
      _nameController.text = cost.name;
      _amountController.text = Formatters.formatNumber(cost.amount);
    });
    _scrollToForm();
  }

  void _scrollToForm() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _formKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 250),
          alignment: 0.2,
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _confirmDraft() {
    final amount = Formatters.parseNumber(_amountController.text);
    if (amount <= 0) return;

    if (_editingCostId != null) {
      widget.onUpdateCostAmount?.call(_editingCostId!, amount);
    } else if (_draftCustom) {
      final name = _nameController.text.trim();
      if (name.isEmpty) return;
      widget.onAddCost?.call(CostItem(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        amount: amount,
        category: CostCategory.other,
      ));
    } else if (_draftTemplate != null) {
      widget.onAddCost?.call(_draftTemplate!.toCostItem(amount: amount));
    }
    _clearDraft();
  }

  String get _draftTitle {
    if (_editingCostId != null) {
      return _nameController.text.isNotEmpty
          ? _nameController.text
          : 'Tutarı güncelle';
    }
    if (_draftCustom) return 'Özel maliyet';
    return _draftTemplate?.name ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final home = widget.home;
    final isEditable = widget.onAddCost != null;
    final showDraft =
        _draftTemplate != null || _draftCustom || _editingCostId != null;

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

            _CostRow(
              label: 'Ev fiyatı',
              value: home.price > 0 ? Formatters.formatTL(home.price) : '—',
            ),
            _CostRow(
              label:
                  'Alım-satım vergisi ${Formatters.formatPercent(home.taxRate)}',
              value: home.price > 0 ? Formatters.formatTL(home.tax) : '—',
            ),
            _CostRow(
              label: home.commRate == 0
                  ? 'Emlakçı (sahibinden)'
                  : 'Emlakçı komisyonu ${Formatters.formatPercent(home.commRate)}',
              value:
                  home.price > 0 ? Formatters.formatTL(home.commission) : '—',
            ),
            if (home.hasValidInput)
              _CostRow(
                label: 'Döner sermaye',
                value: Formatters.formatTL(HomeModel.donerSermaye),
              ),
            if (home.needsLoan)
              _CostRow(
                label: 'Döner sermaye - ipotek borcu',
                value: Formatters.formatTL(HomeModel.donerSermaye),
              ),
            if (home.reno > 0)
              _CostRow(
                label: 'Tadilat',
                value: Formatters.formatTL(home.reno),
              ),

            ...home.additionalCosts.map((cost) => _CostRow(
                  label: cost.name,
                  value: Formatters.formatTL(cost.amount),
                  onRemove:
                      isEditable ? () => widget.onRemoveCost?.call(cost.id) : null,
                  onEdit: isEditable ? () => _startEdit(cost) : null,
                )),

            if (isEditable) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() {
                  _isExpanded = !_isExpanded;
                  if (!_isExpanded) _clearDraft();
                }),
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

              if (_isExpanded) ...[
                const SizedBox(height: 12),
                _QuickCostChips(
                  existingCostIds:
                      home.additionalCosts.map((c) => c.id).toSet(),
                  selectedId: _draftTemplate?.id,
                  customSelected: _draftCustom,
                  onSelect: _startTemplate,
                  onCustom: _startCustom,
                ),
                if (showDraft) ...[
                  const SizedBox(height: 12),
                  KeyedSubtree(
                    key: _formKey,
                    child: _InlineAmountForm(
                      title: _draftTitle,
                      showNameField: _draftCustom,
                      nameController: _nameController,
                      amountController: _amountController,
                      confirmLabel:
                          _editingCostId != null ? 'Kaydet' : 'Ekle',
                      onCancel: _clearDraft,
                      onConfirm: _confirmDraft,
                    ),
                  ),
                ],
              ],
            ],

            const SizedBox(height: 16),

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
                    child: const Icon(
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
                          home.price > 0
                              ? Formatters.formatTL(home.totalCost)
                              : '—',
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
}

class _InlineAmountForm extends StatelessWidget {
  final String title;
  final bool showNameField;
  final TextEditingController nameController;
  final TextEditingController amountController;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _InlineAmountForm({
    required this.title,
    required this.showNameField,
    required this.nameController,
    required this.amountController,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
  });

  void _formatAmount() {
    final text = amountController.text;
    final formatted = Formatters.formatInputValue(text);
    if (formatted != text) {
      amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.fraunces(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 12),
          if (showNameField) ...[
            TextField(
              controller: nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Maliyet adı',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Tutar (TL)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            onChanged: (_) => _formatAmount(),
            onSubmitted: (_) => onConfirm(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('İptal'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  child: Text(confirmLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickCostChips extends StatelessWidget {
  final Set<String> existingCostIds;
  final String? selectedId;
  final bool customSelected;
  final ValueChanged<CostTemplate> onSelect;
  final VoidCallback onCustom;

  const _QuickCostChips({
    required this.existingCostIds,
    required this.selectedId,
    required this.customSelected,
    required this.onSelect,
    required this.onCustom,
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
            final isSelected = selectedId == template.id;
            return GestureDetector(
              onTap: isAdded ? null : () => onSelect(template),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isAdded
                      ? AppColors.forest
                      : (isSelected ? AppColors.goldSoft : Colors.white),
                  border: Border.all(
                    color: isAdded || isSelected
                        ? AppColors.forest
                        : AppColors.line,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isAdded)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child:
                            Icon(Icons.check, size: 14, color: Colors.white),
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
        GestureDetector(
          onTap: onCustom,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: customSelected ? AppColors.goldSoft : Colors.white,
              border: Border.all(
                color: customSelected ? AppColors.forest : AppColors.line,
              ),
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
