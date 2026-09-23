import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class HeroCard extends StatelessWidget {
  final double loanAmount;
  final double totalCost;
  final double cash;
  final bool hasValidInput;

  const HeroCard({
    super.key,
    required this.loanAmount,
    required this.totalCost,
    required this.cash,
    this.hasValidInput = true,
  });

  String get _loanText {
    if (!hasValidInput) return '—';
    if (loanAmount > 0) return Formatters.formatTL(loanAmount);
    return 'Kredi gerekmez';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Dekoratif daire
          Positioned(
            right: -40,
            top: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withOpacity(0.18),
              ),
            ),
          ),
          // İçerik
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Çekilecek kredi',
                  style: GoogleFonts.fraunces(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white.withOpacity(0.78),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _loanText,
                  style: GoogleFonts.fraunces(
                    fontSize: 44,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                    letterSpacing: -0.04 * 44,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _Chip(
                        label: 'Toplam maliyet',
                        value: hasValidInput ? Formatters.formatTL(totalCost) : '—',
                        isHighlighted: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Chip(
                        label: 'Nakit',
                        value: Formatters.formatTL(cash),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const _Chip({
    required this.label, 
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted 
            ? AppColors.gold.withOpacity(0.2)
            : Colors.white.withOpacity(0.08),
        border: Border.all(
          color: isHighlighted 
              ? AppColors.gold.withOpacity(0.4)
              : Colors.white.withOpacity(0.12),
          width: isHighlighted ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Formatters.upperTr(label),
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.08 * 11,
              color: isHighlighted 
                  ? AppColors.gold
                  : AppColors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: isHighlighted ? 18 : 16,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
