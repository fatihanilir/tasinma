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
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Column(
                                children: [
                                  _HeaderRow(a: a, b: b),
                                  _MoneyRow(
                                    label: 'Toplam maliyet',
                                    valueA: a.totalCost,
                                    valueB: b.totalCost,
                                    emphasize: true,
                                  ),
                                  _MoneyRow(
                                    label: 'Çekilecek kredi',
                                    valueA: a.loanAmount,
                                    valueB: b.loanAmount,
                                    emphasize: true,
                                    zeroLabel: 'Yok',
                                  ),
                                  _MoneyRow(
                                    label: 'Ev fiyatı',
                                    valueA: a.price,
                                    valueB: b.price,
                                  ),
                                  _CompareRow(
                                    label: 'Aylık faiz',
                                    cellA: _ValueCell(
                                      text: Formatters.formatPercent(
                                          a.interestRate),
                                      alignRight: false,
                                    ),
                                    cellB: _ValueCell(
                                      text: Formatters.formatPercent(
                                          b.interestRate),
                                      alignRight: true,
                                    ),
                                    isLast: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Column(
                                children: [
                                  Text(
                                    'VADELER VE AYLIK ÖDEME',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.1 * 11,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _PaymentRow(
                                    label: sameTerms
                                        ? '${a.term1} ay vade'
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
                                        ? '${a.term2} ay vade'
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
                          _Summary(a: a, b: b, sameTerms: sameTerms),
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

class _HeaderRow extends StatelessWidget {
  final HomeModel a;
  final HomeModel b;

  const _HeaderRow({required this.a, required this.b});

  Widget _title(String text, TextAlign align) => Expanded(
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: GoogleFonts.fraunces(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.forest,
            height: 1.2,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          _title(a.displayTitle, TextAlign.left),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'vs',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.forest2,
              ),
            ),
          ),
          _title(b.displayTitle, TextAlign.right),
        ],
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  final String label;
  final Widget cellA;
  final Widget cellB;
  final bool emphasize;
  final bool isLast;

  const _CompareRow({
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
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: emphasize ? FontWeight.w600 : FontWeight.w500,
              color: emphasize ? AppColors.forest : AppColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cellA),
              const SizedBox(width: 12),
              Expanded(child: cellB),
            ],
          ),
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
  final bool alignRight;

  const _ValueCell({
    required this.text,
    required this.alignRight,
    this.subText,
    this.better = false,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = better ? AppColors.forest : AppColors.ink;
    final align = alignRight ? TextAlign.right : TextAlign.left;
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          padding: better
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
              : EdgeInsets.zero,
          decoration: better
              ? BoxDecoration(
                  color: AppColors.forest.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Text(
            text,
            textAlign: align,
            style: emphasize
                ? GoogleFonts.fraunces(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: color,
                  )
                : GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
          ),
        ),
        if (subText != null) ...[
          const SizedBox(height: 3),
          Text(
            subText!,
            textAlign: align,
            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ],
    );
  }
}

class _MoneyRow extends StatelessWidget {
  final String label;
  final double valueA;
  final double valueB;
  final bool emphasize;
  final String zeroLabel;

  const _MoneyRow({
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
    return _CompareRow(
      label: label,
      emphasize: emphasize,
      cellA: _ValueCell(
        text: _fmt(valueA),
        alignRight: false,
        better: differs && valueA < valueB,
        emphasize: emphasize,
      ),
      cellB: _ValueCell(
        text: _fmt(valueB),
        alignRight: true,
        better: differs && valueB < valueA,
        emphasize: emphasize,
      ),
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

  _ValueCell _cell(
    int months,
    double payment,
    double total,
    bool better,
    bool alignRight,
  ) {
    if (payment <= 0) {
      return _ValueCell(
        text: 'Kredi yok',
        subText: showMonths ? '$months ay' : null,
        alignRight: alignRight,
      );
    }
    final prefix = showMonths ? '$months ay · ' : '';
    return _ValueCell(
      text: '${Formatters.formatTL(payment)}/ay',
      subText: '${prefix}toplam ${Formatters.formatTL(total)}',
      better: better,
      alignRight: alignRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final differs =
        (paymentA - paymentB).abs() >= 1 && paymentA > 0 && paymentB > 0;
    return _CompareRow(
      label: label,
      isLast: isLast,
      cellA: _cell(
          monthsA, paymentA, totalA, differs && paymentA < paymentB, false),
      cellB: _cell(
          monthsB, paymentB, totalB, differs && paymentB < paymentA, true),
    );
  }
}

class _Summary extends StatelessWidget {
  final HomeModel a;
  final HomeModel b;
  final bool sameTerms;

  const _Summary({required this.a, required this.b, required this.sameTerms});

  String? _paymentLine(String termLabel, double pa, double pb) {
    if (pa <= 0 || pb <= 0) return null;
    final diff = (pa - pb).abs();
    if (diff < 1) return null;
    final lower = pa < pb ? a : b;
    return '${lower.displayTitle} $termLabel aylık ödemesi ${Formatters.formatTL(diff)} daha düşük.';
  }

  @override
  Widget build(BuildContext context) {
    final lines = <String>[];

    final costDiff = (a.totalCost - b.totalCost).abs();
    if (costDiff < 1) {
      lines.add('İki evin toplam maliyeti aynı.');
    } else {
      final lower = a.totalCost < b.totalCost ? a : b;
      lines.add(
          '${lower.displayTitle} toplamda ${Formatters.formatTL(costDiff)} daha düşük maliyetli.');
    }

    final p1 = _paymentLine(
      sameTerms ? '${a.term1} ay vadede' : '1. vadede',
      a.paymentTerm1,
      b.paymentTerm1,
    );
    final p2 = _paymentLine(
      sameTerms ? '${a.term2} ay vadede' : '2. vadede',
      a.paymentTerm2,
      b.paymentTerm2,
    );
    if (p1 != null) lines.add(p1);
    if (p2 != null) lines.add(p2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    i == 0
                        ? Icons.account_balance_wallet_rounded
                        : Icons.calendar_month_rounded,
                    color: AppColors.gold,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lines[i],
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: i == 0 ? FontWeight.w600 : FontWeight.w500,
                      color: AppColors.white,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
