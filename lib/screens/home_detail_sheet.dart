import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/home_model.dart';
import '../theme/app_theme.dart';
import '../widgets/hero_card.dart';
import '../widgets/payment_card.dart';
import '../widgets/cost_breakdown.dart';

class HomeDetailSheet extends StatelessWidget {
  final HomeModel home;

  const HomeDetailSheet({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF7F2EA), Color(0xFFEFE6D8)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        home.displayTitle,
                        style: GoogleFonts.fraunces(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.03 * 24,
                          color: AppColors.forest,
                        ),
                      ),
                      if (home.hasLink) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final uri = Uri.tryParse(home.normalizedLink);
                            if (uri != null) {
                              // ignore: use_build_context_synchronously
                            }
                          },
                          child: Text(
                            home.normalizedLink,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppColors.forest2,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Kapat',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.forest2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + bottomPadding),
              child: Column(
                children: [
                  // Hero kart
                  HeroCard(
                    loanAmount: home.loanAmount,
                    totalCost: home.totalCost,
                    cash: home.cash,
                    hasValidInput: home.hasValidInput,
                  ),
                  const SizedBox(height: 14),

                  // Ödeme planları
                  PaymentCardsRow(
                    term1: home.term1,
                    term2: home.term2,
                    paymentTerm1: home.paymentTerm1,
                    paymentTerm2: home.paymentTerm2,
                    totalPaymentTerm1: home.totalPaymentTerm1,
                    totalPaymentTerm2: home.totalPaymentTerm2,
                    needsLoan: home.needsLoan,
                  ),
                  const SizedBox(height: 14),

                  // Maliyet kırılımı
                  CostBreakdown(home: home),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
