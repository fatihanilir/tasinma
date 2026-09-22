import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class PaymentCard extends StatelessWidget {
  final int months;
  final double payment;
  final double totalPayment;
  final bool needsLoan;
  final VoidCallback? onTap;

  const PaymentCard({
    super.key,
    required this.months,
    required this.payment,
    required this.totalPayment,
    required this.needsLoan,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final years = months / 12;
    final hasFullYear = months % 12 == 0;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF8),
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vade başlığı ve değiştir butonu
            Row(
              children: [
                Text(
                  hasFullYear
                      ? '$months Ay · ${years.toInt()} Yıl'
                      : '$months Ay',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forest2,
                  ),
                ),
                if (onTap != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.forest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Değiştir',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              needsLoan ? Formatters.formatTL(payment) : '—',
              style: GoogleFonts.fraunces(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.03 * 26,
                color: AppColors.forest,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Aylık ödeme',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (needsLoan) ...[
              const SizedBox(height: 2),
              Text(
                'Toplam geri ödeme ${Formatters.formatTL(totalPayment)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PaymentCardsRow extends StatelessWidget {
  final int term1;
  final int term2;
  final double paymentTerm1;
  final double paymentTerm2;
  final double totalPaymentTerm1;
  final double totalPaymentTerm2;
  final bool needsLoan;
  final ValueChanged<int>? onTerm1Changed;
  final ValueChanged<int>? onTerm2Changed;

  const PaymentCardsRow({
    super.key,
    required this.term1,
    required this.term2,
    required this.paymentTerm1,
    required this.paymentTerm2,
    required this.totalPaymentTerm1,
    required this.totalPaymentTerm2,
    required this.needsLoan,
    this.onTerm1Changed,
    this.onTerm2Changed,
  });

  void _showTermPicker(BuildContext context, int currentTerm, ValueChanged<int>? onChanged) {
    if (onChanged == null) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TermPickerSheet(
        currentTerm: currentTerm,
        onSelected: (value) {
          Navigator.pop(ctx);
          onChanged(value);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 400) {
          // Dar ekranda alt alta
          return Column(
            children: [
              PaymentCard(
                months: term1,
                payment: paymentTerm1,
                totalPayment: totalPaymentTerm1,
                needsLoan: needsLoan,
                onTap: onTerm1Changed != null
                    ? () => _showTermPicker(context, term1, onTerm1Changed)
                    : null,
              ),
              const SizedBox(height: 12),
              PaymentCard(
                months: term2,
                payment: paymentTerm2,
                totalPayment: totalPaymentTerm2,
                needsLoan: needsLoan,
                onTap: onTerm2Changed != null
                    ? () => _showTermPicker(context, term2, onTerm2Changed)
                    : null,
              ),
            ],
          );
        }
        // Geniş ekranda yan yana
        return Row(
          children: [
            Expanded(
              child: PaymentCard(
                months: term1,
                payment: paymentTerm1,
                totalPayment: totalPaymentTerm1,
                needsLoan: needsLoan,
                onTap: onTerm1Changed != null
                    ? () => _showTermPicker(context, term1, onTerm1Changed)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PaymentCard(
                months: term2,
                payment: paymentTerm2,
                totalPayment: totalPaymentTerm2,
                needsLoan: needsLoan,
                onTap: onTerm2Changed != null
                    ? () => _showTermPicker(context, term2, onTerm2Changed)
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }
}

// Term Picker Sheet (from term_selector.dart)
class _TermPickerSheet extends StatefulWidget {
  final int currentTerm;
  final ValueChanged<int> onSelected;

  const _TermPickerSheet({
    required this.currentTerm,
    required this.onSelected,
  });

  @override
  State<_TermPickerSheet> createState() => _TermPickerSheetState();
}

class _TermPickerSheetState extends State<_TermPickerSheet> {
  late TextEditingController _controller;
  late int _selectedTerm;
  
  static const List<int> commonTerms = [36, 48, 60, 72, 84, 96, 120, 180];

  @override
  void initState() {
    super.initState();
    _selectedTerm = widget.currentTerm;
    _controller = TextEditingController(text: widget.currentTerm.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectTerm(int term) {
    setState(() {
      _selectedTerm = term;
      _controller.text = term.toString();
    });
  }

  void _applyCustomTerm() {
    final value = int.tryParse(_controller.text) ?? 60;
    final clampedValue = value.clamp(6, 360);
    widget.onSelected(clampedValue);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFDF8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
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
              const SizedBox(height: 20),
              Text(
                'Vade Seçin',
                style: GoogleFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.goldSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(3),
                              ],
                              style: GoogleFonts.fraunces(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: AppColors.forest,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '60',
                              ),
                              onChanged: (value) {
                                final parsed = int.tryParse(value);
                                if (parsed != null) {
                                  setState(() => _selectedTerm = parsed);
                                }
                              },
                            ),
                          ),
                          Text(
                            'ay',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: AppColors.forest2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _applyCustomTerm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    child: const Text('Uygula'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'YAYGIN VADELER',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1 * 11,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: commonTerms.map((term) {
                  final isSelected = term == _selectedTerm;
                  final years = term / 12;
                  return GestureDetector(
                    onTap: () => _selectTerm(term),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.forest : Colors.white,
                        border: Border.all(
                          color: isSelected ? AppColors.forest : AppColors.line,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$term ay',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppColors.white : AppColors.forest,
                            ),
                          ),
                          if (term % 12 == 0)
                            Text(
                              '${years.toInt()} yıl',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: isSelected
                                    ? AppColors.white.withOpacity(0.7)
                                    : AppColors.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
