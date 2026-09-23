import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/home_model.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class CompareHomesScreen extends StatelessWidget {
  final HomeModel a;
  final HomeModel b;

  const CompareHomesScreen({super.key, required this.a, required this.b});

  @override
  Widget build(BuildContext context) {
    final sameTerms = a.term1 == b.term1 && a.term2 == b.term2;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 18, 12),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: AppColors.forest),
                        ),
                        Text(
                          'Karşılaştır',
                          style: GoogleFonts.fraunces(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.02 * 24,
                            color: AppColors.forest,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
                      child: Column(
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _HeaderRow(a: a, b: b),
                                  const SizedBox(height: 8),
                                  _CompareRow(
                                    label: 'Toplam maliyet',
                                    valueA: a.totalCost,
                                    valueB: b.totalCost,
                                    emphasize: true,
                                  ),
                                  _CompareRow(
                                    label: 'Çekilecek kredi',
                                    valueA: a.loanAmount,
                                    valueB: b.loanAmount,
                                    emphasize: true,
                                    zeroLabel: 'Yok',
                                  ),
                                  _CompareRow(
                                    label: 'Ev fiyatı',
                                    valueA: a.price,
                                    valueB: b.price,
                                  ),
                                  _TextRow(
                                    label: 'Aylık faiz',
                                    textA: Formatters.formatPercent(
                                        a.interestRate),
                                    textB: Formatters.formatPercent(
                                        b.interestRate),
                                  ),
                                  const SizedBox(height: 12),
                                  _SectionLabel('VADELER VE AYLIK ÖDEME'),
                                  _PaymentRow(
                                    label: sameTerms
                                        ? '${a.term1} ay'
                                        : '1. vade',
                                    monthsA: a.term1,
                                    monthsB: b.term1,
                                    paymentA: a.paymentTerm1,
                                    paymentB: b.paymentTerm1,
                                    totalA: a.totalPaymentTerm1,
                                    totalB: b.totalPaymentTerm1,
                                    showMonths: !sameTerms,
                                  ),
                                  _PaymentRow(
                                    label: sameTerms
                                        ? '${a.term2} ay'
                                        : '2. vade',
                                    monthsA: a.term2,
                                    monthsB: b.term2,
                                    paymentA: a.paymentTerm2,
                                    paymentB: b.paymentTerm2,
                                    totalA: a.totalPaymentTerm2,
                                    totalB: b.totalPaymentTerm2,
                                    showMonths: !sameTerms,
                                    isLast: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _Summary(a: a, b: b),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _labelFlex = 4;
const _valueFlex = 5;

class _HeaderRow extends StatelessWidget {
  final HomeModel a;
  final HomeModel b;

  const _HeaderRow({required this.a, required this.b});

  Widget _title(String text) => Expanded(
        flex: _valueFlex,
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: GoogleFonts.fraunces(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.forest,
            height: 1.2,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Expanded(flex: _labelFlex, child: SizedBox()),
          _title(a.displayTitle),
          const SizedBox(width: 10),
          _title(b.displayTitle),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1 * 11,
          color: AppColors.muted,
        ),
      ),
    );
  }
}

class _RowShell extends StatelessWidget {
  final String label;
  final Widget cellA;
  final Widget cellB;
  final bool emphasize;
  final bool isLast;

  const _RowShell({
    required this.label,
    required this.cellA,
    required this.cellB,
    this.emphasize = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: _labelFlex,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: emphasize ? FontWeight.w600 : FontWeight.w400,
                color: emphasize ? AppColors.forest : AppColors.muted,
              ),
            ),
          ),
          Expanded(flex: _valueFlex, child: cellA),
          const SizedBox(width: 10),
          Expanded(flex: _valueFlex, child: cellB),
        ],
      ),
    );
  }
}

class _ValueCell extends StatelessWidget {
  final String text;
  final String? subText;
  final bool better;
  final bool emphasize;

  const _ValueCell({
    required this.text,
    this.subText,
    this.better = false,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = better ? AppColors.forest : AppColors.ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: better
              ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
              : EdgeInsets.zero,
          decoration: better
              ? BoxDecoration(
                  color: AppColors.forest.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                )
              : null,
          child: Text(
            text,
            textAlign: TextAlign.right,
            style: emphasize
                ? GoogleFonts.fraunces(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  )
                : GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
          ),
        ),
        if (subText != null) ...[
          const SizedBox(height: 2),
          Text(
            subText!,
            textAlign: TextAlign.right,
            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ],
    );
  }
}

class _CompareRow extends StatelessWidget {
  final String label;
  final double valueA;
  final double valueB;
  final bool emphasize;
  final String zeroLabel;

  const _CompareRow({
    required this.label,
    required this.valueA,
    required this.valueB,
    this.emphasize = false,
    this.zeroLabel = '—',
  });

  String _fmt(double v) => v > 0 ? Formatters.formatTL(v) : zeroLabel;

  @override
  Widget build(BuildContext context) {
    final differs = (valueA - valueB).abs() >= 1;
    return _RowShell(
      label: label,
      emphasize: emphasize,
      cellA: _ValueCell(
        text: _fmt(valueA),
        better: differs && valueA < valueB,
        emphasize: emphasize,
      ),
      cellB: _ValueCell(
        text: _fmt(valueB),
        better: differs && valueB < valueA,
        emphasize: emphasize,
      ),
    );
  }
}

class _TextRow extends StatelessWidget {
  final String label;
  final String textA;
  final String textB;

  const _TextRow({
    required this.label,
    required this.textA,
    required this.textB,
  });

  @override
  Widget build(BuildContext context) {
    return _RowShell(
      label: label,
      cellA: _ValueCell(text: textA),
      cellB: _ValueCell(text: textB),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final String label;
  final int monthsA;
  final int monthsB;
  final double paymentA;
  final double paymentB;
  final double totalA;
  final double totalB;
  final bool showMonths;
  final bool isLast;

  const _PaymentRow({
    required this.label,
    required this.monthsA,
    required this.monthsB,
    required this.paymentA,
    required this.paymentB,
    required this.totalA,
    required this.totalB,
    this.showMonths = false,
    this.isLast = false,
  });

  _ValueCell _cell(int months, double payment, double total, bool better) {
    if (payment <= 0) {
      return _ValueCell(
        text: 'Kredi yok',
        subText: showMonths ? '$months ay' : null,
      );
    }
    final prefix = showMonths ? '$months ay · ' : '';
    return _ValueCell(
      text: '${Formatters.formatTL(payment)}/ay',
      subText: '${prefix}toplam ${Formatters.formatTL(total)}',
      better: better,
    );
  }

  @override
  Widget build(BuildContext context) {
    final differs = (paymentA - paymentB).abs() >= 1 &&
        paymentA > 0 &&
        paymentB > 0;
    return _RowShell(
      label: label,
      isLast: isLast,
      cellA: _cell(monthsA, paymentA, totalA, differs && paymentA < paymentB),
      cellB: _cell(monthsB, paymentB, totalB, differs && paymentB < paymentA),
    );
  }
}

class _Summary extends StatelessWidget {
  final HomeModel a;
  final HomeModel b;

  const _Summary({required this.a, required this.b});

  @override
  Widget build(BuildContext context) {
    final diff = (a.totalCost - b.totalCost).abs();
    final String text;
    if (diff < 1) {
      text = 'İki evin toplam maliyeti aynı.';
    } else {
      final cheaper = a.totalCost < b.totalCost ? a : b;
      text =
          '${cheaper.displayTitle} toplamda ${Formatters.formatTL(diff)} daha ucuz.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.compare_arrows_rounded,
              color: AppColors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
