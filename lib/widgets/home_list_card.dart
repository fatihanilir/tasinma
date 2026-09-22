import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/home_model.dart';
import '../utils/formatters.dart';

class HomeListCard extends StatelessWidget {
  final HomeModel home;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final bool isFirst;
  final bool isLast;

  const HomeListCard({
    super.key,
    required this.home,
    required this.onTap,
    required this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
    this.isFirst = false,
    this.isLast = false,
  });

  Future<void> _openLink() async {
    if (home.link.isEmpty) return;
    final uri = Uri.tryParse(home.link);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ana içerik
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık
                    Text(
                      home.displayTitle,
                      style: GoogleFonts.fraunces(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.02 * 20,
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Meta bilgiler
                    Text(
                      '${Formatters.formatTL(home.price)} · kredi ${home.needsLoan ? Formatters.formatTL(home.loanAmount) : "yok"}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.muted,
                        height: 1.45,
                      ),
                    ),
                    Text(
                      '60 ay ${home.needsLoan ? Formatters.formatTL(home.payment60) : "—"} · 120 ay ${home.needsLoan ? Formatters.formatTL(home.payment120) : "—"}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.muted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Aksiyon butonları
                    Row(
                      children: [
                        if (home.link.isNotEmpty &&
                            home.link.startsWith('http'))
                          _MiniButton(
                            label: 'İlan',
                            onTap: _openLink,
                          ),
                        if (home.link.isNotEmpty &&
                            home.link.startsWith('http'))
                          const SizedBox(width: 8),
                        _MiniButton(
                          label: 'Sil',
                          isDanger: true,
                          onTap: onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Sıralama butonları
            Column(
              children: [
                _RankButton(
                  icon: Icons.keyboard_arrow_up,
                  onTap: isFirst ? null : onMoveUp,
                ),
                const SizedBox(height: 6),
                _RankButton(
                  icon: Icons.keyboard_arrow_down,
                  onTap: isLast ? null : onMoveDown,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  const _MiniButton({
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDanger ? AppColors.coral : AppColors.forest2,
          ),
        ),
      ),
    );
  }
}

class _RankButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RankButton({
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDisabled
              ? AppColors.muted.withOpacity(0.35)
              : AppColors.forest2,
        ),
      ),
    );
  }
}
