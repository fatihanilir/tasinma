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
  final VoidCallback? onEdit;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final bool isFirst;
  final bool isLast;

  const HomeListCard({
    super.key,
    required this.home,
    required this.onTap,
    required this.onDelete,
    this.onEdit,
    this.onMoveUp,
    this.onMoveDown,
    this.isFirst = false,
    this.isLast = false,
  });

  Future<void> _openLink() async {
    final link = home.normalizedLink;
    if (link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onTap,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        Text(
                          '${Formatters.formatTL(home.price)} · kredi ${home.needsLoan ? Formatters.formatTL(home.loanAmount) : "yok"}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppColors.muted,
                            height: 1.45,
                          ),
                        ),
                        Text(
                          '${home.term1} ay ${home.needsLoan ? Formatters.formatTL(home.paymentTerm1) : "—"} · ${home.term2} ay ${home.needsLoan ? Formatters.formatTL(home.paymentTerm2) : "—"}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppColors.muted,
                            height: 1.45,
                          ),
                        ),
                        if (home.hasLink) ...[
                          const SizedBox(height: 6),
                          Text(
                            home.normalizedLink,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.forest2,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (onEdit != null) ...[
                        _MiniButton(
                          label: 'Düzenle',
                          onTap: onEdit!,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (home.hasLink) ...[
                        _MiniButton(
                          label: 'İlan',
                          onTap: _openLink,
                        ),
                        const SizedBox(width: 8),
                      ],
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
            const SizedBox(width: 8),
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
