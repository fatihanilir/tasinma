import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class MoneyInput extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final String? hint;

  const MoneyInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  @override
  State<MoneyInput> createState() => _MoneyInputState();
}

class _MoneyInputState extends State<MoneyInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value > 0 ? Formatters.formatNumber(widget.value) : '',
    );
  }

  @override
  void didUpdateWidget(MoneyInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Dışarıdan value değişirse güncelle
    final currentValue = Formatters.parseNumber(_controller.text);
    if (currentValue != widget.value) {
      _controller.text = widget.value > 0 ? Formatters.formatNumber(widget.value) : '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    final number = Formatters.parseNumber(text);
    final formatted = Formatters.formatInputValue(text);
    
    if (formatted != text) {
      _controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    
    widget.onChanged(number);
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
              Formatters.upperTr(widget.label),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: _onChanged,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    style: GoogleFonts.fraunces(
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      color: AppColors.forest,
                      letterSpacing: -0.03 * 34,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Text(
                  'TL',
                  style: GoogleFonts.fraunces(
                    fontSize: 18,
                    color: AppColors.forest,
                  ),
                ),
              ],
            ),
            Container(
              height: 1.5,
              color: AppColors.forest,
            ),
            if (widget.hint != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.hint!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
