import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/homes_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_banner_placeholder.dart';
import '../widgets/money_input.dart';
import '../widgets/segment_control.dart';
import '../widgets/hero_card.dart';
import '../widgets/payment_card.dart';
import '../widgets/cost_breakdown.dart';
import '../widgets/text_input.dart';
import '../widgets/interest_rate_input.dart';

class CalculatorScreen extends StatefulWidget {
  final VoidCallback onSave;
  final VoidCallback onNew;

  const CalculatorScreen({
    super.key,
    required this.onSave,
    required this.onNew,
  });

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _scrollController = ScrollController();
  final _parkKey = GlobalKey();
  bool _parked = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updatePark);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePark());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updatePark);
    _scrollController.dispose();
    super.dispose();
  }

  void _updatePark() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (!auth.showStickyCalculatorAd) return;

    final ctx = _parkKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final top = box.localToGlobal(Offset.zero).dy;
    final screenH = MediaQuery.sizeOf(context).height;
    final stickLine = screenH - 140;
    final shouldPark = top <= stickLine;
    if (shouldPark != _parked) {
      setState(() => _parked = shouldPark);
    }
  }

  String? _getWarningMessage(double price, double loanAmount) {
    if (price <= 0) {
      return 'Hesap için ev fiyatını gir.';
    } else if (loanAmount <= 0) {
      return 'Nakit, toplam maliyeti karşılıyor. Kredi çekmene gerek yok.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sticky = auth.showStickyCalculatorAd;
    final fixed = auth.showFixedCalculatorAd;

    return Consumer<HomesProvider>(
      builder: (context, provider, _) {
        final home = provider.tempHome;
        final warningMessage = _getWarningMessage(home.price, home.loanAmount);

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                child: Column(
                  children: [
                    MoneyInput(
                      label: 'Evin fiyatı',
                      value: home.price,
                      onChanged: (v) => provider.updateTempHome(price: v),
                    ),
                    const SizedBox(height: 14),
                    MoneyInput(
                      label: 'Elindeki nakit',
                      value: home.cash,
                      onChanged: (v) => provider.updateTempHome(cash: v),
                    ),
                    const SizedBox(height: 14),
                    MoneyInput(
                      label: 'Tadilat masrafı',
                      value: home.reno,
                      onChanged: (v) => provider.updateTempHome(reno: v),
                      hint:
                          'Vergi ve emlakçı komisyonuna girmez; toplam maliyete ve krediye eklenir.',
                    ),
                    const SizedBox(height: 14),
                    SegmentControl<double>(
                      label: 'Alım-satım vergisi',
                      options: const [
                        SegmentOption(value: 0.02, label: '%2'),
                        SegmentOption(value: 0.04, label: '%4'),
                      ],
                      selectedValue: home.taxRate,
                      onChanged: (v) => provider.updateTempHome(taxRate: v),
                    ),
                    const SizedBox(height: 14),
                    SegmentControl<double>(
                      label: 'Emlakçı komisyonu',
                      options: const [
                        SegmentOption(value: 0, label: 'Sahibinden'),
                        SegmentOption(value: 0.02, label: '%2'),
                      ],
                      selectedValue: home.commRate,
                      onChanged: (v) => provider.updateTempHome(commRate: v),
                    ),
                    const SizedBox(height: 14),
                    InterestRateInput(
                      value: home.interestRate,
                      onChanged: (v) =>
                          provider.updateTempHome(interestRate: v),
                    ),
                    const SizedBox(height: 14),
                    HeroCard(
                      loanAmount: home.loanAmount,
                      totalCost: home.totalCost,
                      cash: home.cash,
                      hasValidInput: home.hasValidInput,
                    ),
                    const SizedBox(height: 14),
                    PaymentCardsRow(
                      term1: home.term1,
                      term2: home.term2,
                      paymentTerm1: home.paymentTerm1,
                      paymentTerm2: home.paymentTerm2,
                      totalPaymentTerm1: home.totalPaymentTerm1,
                      totalPaymentTerm2: home.totalPaymentTerm2,
                      needsLoan: home.needsLoan,
                      onTerm1Changed: (v) => provider.updateTempHome(term1: v),
                      onTerm2Changed: (v) => provider.updateTempHome(term2: v),
                    ),
                    const SizedBox(height: 14),
                    CostBreakdown(
                      home: home,
                      warningMessage: warningMessage,
                      onAddCost: provider.addCost,
                      onRemoveCost: provider.removeCost,
                      onUpdateCostAmount: provider.updateCostAmount,
                    ),

                    // Girişli: maliyet kırılımı altında sabit
                    if (fixed) ...[
                      const SizedBox(height: 14),
                      const AdBannerPlaceholder(
                        label: 'Hesap · maliyet kırılımı altı (sabit)',
                        unit: AdUnit.inArticle,
                      ),
                    ],

                    // Misafir: park noktası (sticky buraya gelince sabitlenir)
                    if (sticky) ...[
                      const SizedBox(height: 14),
                      KeyedSubtree(
                        key: _parkKey,
                        child: _parked
                            ? const SizedBox(height: 56)
                            : const AdBannerPlaceholder(
                                label: 'Hesap · maliyet kırılımı altı',
                                unit: AdUnit.inArticle,
                              ),
                      ),
                    ],

                    const SizedBox(height: 14),
                    TextInputCard(
                      label: 'İlan linki',
                      value: home.link,
                      onChanged: (v) => provider.updateTempHome(link: v),
                      placeholder: 'https://...',
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 14),
                    TextInputCard(
                      label: 'Başlık',
                      value: home.title,
                      onChanged: (v) => provider.updateTempHome(title: v),
                      placeholder: 'Örn. Caddebostan deniz manzara',
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Sadece planlama içindir. Banka teklifi farklılık gösterebilir.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Misafir sticky: her zaman Kaydet üstünde takip / park sonrası sabit
            if (sticky)
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFE6D8),
                  border: Border(
                    top: BorderSide(color: AppColors.line, width: 1),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                child: const AdBannerPlaceholder(
                  label: 'Hesap · sticky',
                  unit: AdUnit.display,
                  compact: true,
                ),
              ),

            Container(
              padding: EdgeInsets.fromLTRB(
                18,
                12,
                18,
                12 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEFE6D8),
                border: Border(
                  top: BorderSide(
                    color: sticky ? Colors.transparent : AppColors.line,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onNew,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppColors.forest, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Yeni ev'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: widget.onSave,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                              color: AppColors.forest, width: 1.5),
                        ),
                      ),
                      child: const Text('Kaydet'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
