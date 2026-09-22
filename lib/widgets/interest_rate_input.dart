import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class InterestRateInput extends StatefulWidget {
  final double value; // 0.0050 - 0.0500 arası (aylık oran)
  final ValueChanged<double> onChanged;

  const InterestRateInput({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<InterestRateInput> createState() => _InterestRateInputState();
}

class _InterestRateInputState extends State<InterestRateInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isEditing = false;

  // Oran aralığı
  static const double minRate = 0.0050; // %0,50
  static const double maxRate = 0.0500; // %5,00

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatRate(widget.value));
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(InterestRateInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.value != widget.value) {
      _controller.text = _formatRate(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isEditing = _focusNode.hasFocus;
    });
    if (!_focusNode.hasFocus) {
      _applyManualInput();
    }
  }

  String _formatRate(double rate) {
    // 0.0305 -> "3,05"
    final percent = (rate * 100).toStringAsFixed(2);
    return percent.replaceAll('.', ',');
  }

  double _parseRate(String text) {
    // "3,05" -> 0.0305
    final cleaned = text.replaceAll(',', '.').replaceAll('%', '').trim();
    final parsed = double.tryParse(cleaned) ?? 3.05;
    return (parsed / 100).clamp(minRate, maxRate);
  }

  void _applyManualInput() {
    final newRate = _parseRate(_controller.text);
    _controller.text = _formatRate(newRate);
    widget.onChanged(newRate);
  }

  void _onSliderChanged(double value) {
    // Slider değeri 0.01 hassasiyetinde yuvarlansın
    final roundedRate = (value * 10000).round() / 10000;
    _controller.text = _formatRate(roundedRate);
    widget.onChanged(roundedRate);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AYLIK FAİZ ORANI',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 16),
            
            // Oran gösterimi ve manuel giriş
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '%',
                  style: GoogleFonts.fraunces(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                      LengthLimitingTextInputFormatter(5),
                      _AutoCommaFormatter(),
                    ],
                    style: GoogleFonts.fraunces(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: AppColors.forest,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.forest.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.forest,
                          width: 2,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _applyManualInput(),
                  ),
                ),
                const Spacer(),
                // Min-Max gösterimi
                Text(
                  '${_formatRate(minRate)} - ${_formatRate(maxRate)}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.forest,
                inactiveTrackColor: AppColors.goldSoft,
                thumbColor: AppColors.forest,
                overlayColor: AppColors.forest.withOpacity(0.12),
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 10,
                ),
              ),
              child: Slider(
                value: widget.value.clamp(minRate, maxRate),
                min: minRate,
                max: maxRate,
                divisions: 450, // (5.00 - 0.50) / 0.01 = 450
                onChanged: _onSliderChanged,
              ),
            ),
            
            // Hızlı seçim butonları
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _QuickButton(
                  label: '%2,50',
                  isSelected: (widget.value - 0.0250).abs() < 0.0001,
                  onTap: () => widget.onChanged(0.0250),
                ),
                _QuickButton(
                  label: '%3,05',
                  isSelected: (widget.value - 0.0305).abs() < 0.0001,
                  onTap: () => widget.onChanged(0.0305),
                ),
                _QuickButton(
                  label: '%3,50',
                  isSelected: (widget.value - 0.0350).abs() < 0.0001,
                  onTap: () => widget.onChanged(0.0350),
                ),
                _QuickButton(
                  label: '%4,00',
                  isSelected: (widget.value - 0.0400).abs() < 0.0001,
                  onTap: () => widget.onChanged(0.0400),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.forest : AppColors.goldSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.white : AppColors.forest2,
          ),
        ),
      ),
    );
  }
}

/// İlk rakamdan sonra otomatik virgül ekleyen formatter
class _AutoCommaFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    // Boş veya zaten virgül varsa dokunma
    if (text.isEmpty || text.contains(',') || text.contains('.')) {
      return newValue;
    }
    
    // Tek rakam girilmişse ve 0-5 arasıysa virgül ekle
    if (text.length == 1 && RegExp(r'^[0-5]$').hasMatch(text)) {
      return TextEditingValue(
        text: '$text,',
        selection: const TextSelection.collapsed(offset: 2),
      );
    }
    
    return newValue;
  }
}
