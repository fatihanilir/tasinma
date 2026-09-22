import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class TermSelector extends StatelessWidget {
  final int term;
  final ValueChanged<int> onChanged;
  final String label;

  const TermSelector({
    super.key,
    required this.term,
    required this.onChanged,
    required this.label,
  });

  // Yaygın vade seçenekleri
  static const List<int> commonTerms = [36, 48, 60, 72, 84, 96, 120, 180];

  void _showTermPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TermPickerSheet(
        currentTerm: term,
        onSelected: (value) {
          Navigator.pop(ctx);
          onChanged(value);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final years = term / 12;
    final hasFullYear = term % 12 == 0;

    return GestureDetector(
      onTap: () => _showTermPicker(context),
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
            Row(
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1 * 11,
                    color: AppColors.muted,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: AppColors.muted.withOpacity(0.6),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$term',
                  style: GoogleFonts.fraunces(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'ay',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.forest2,
                  ),
                ),
              ],
            ),
            if (hasFullYear)
              Text(
                '${years.toInt()} yıl',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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
    final clampedValue = value.clamp(6, 360); // 6 ay - 30 yıl arası
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
              // Handle
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
              
              // Başlık
              Text(
                'Vade Seçin',
                style: GoogleFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(height: 16),
              
              // Manuel giriş
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
              
              // Yaygın seçenekler
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
                children: TermSelector.commonTerms.map((term) {
                  final isSelected = term == _selectedTerm;
                  final years = term / 12;
                  return GestureDetector(
                    onTap: () => _selectTerm(term),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
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
