import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'ad_unit.dart';

export 'ad_unit.dart';

/// Mobil / non-web: placeholder (AdSense yalnızca web).
class AdBannerPlaceholder extends StatelessWidget {
  final String label;
  final bool compact;
  final AdUnit unit;

  const AdBannerPlaceholder({
    super.key,
    this.label = 'Reklam',
    this.compact = false,
    this.unit = AdUnit.display,
  });

  @override
  Widget build(BuildContext context) {
    final height = compact ? 56.0 : unit.minHeight;
    return Semantics(
      label: 'Reklam alanı',
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF0EBE1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Center(
          child: Text(
            '$label\n(${unit.name})',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
