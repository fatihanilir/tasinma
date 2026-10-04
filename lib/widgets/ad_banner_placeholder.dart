import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Yerel / demo AdSense placeholder. Gerçek reklam birimi sonra bağlanır.
class AdBannerPlaceholder extends StatelessWidget {
  final String label;
  final bool compact;

  const AdBannerPlaceholder({
    super.key,
    this.label = 'Reklam',
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = compact ? 56.0 : 90.0;
    return Semantics(
      label: 'Reklam alanı',
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF0EBE1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.line,
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Hafif desen — gerçek reklam hissi
            Positioned.fill(
              child: CustomPaint(painter: _AdStripePainter()),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'REKLAM',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.12 * 11,
                      color: AppColors.muted.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 6,
              right: 8,
              child: Text(
                'AdSense',
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted.withOpacity(0.45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0A1C3D32)
      ..strokeWidth = 1;
    const step = 14.0;
    for (double x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
