import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Klavyenin açık olup olmadığını alt ağaca taşır. Scaffold'un üstüne
/// konmalı: resizeToAvoidBottomInset açıkken Scaffold gövdesi
/// MediaQuery'den klavye yüksekliğini siler, içeride hep 0 görünür.
class KeyboardVisibility extends InheritedWidget {
  const KeyboardVisibility({
    super.key,
    required this.isOpen,
    required super.child,
  });

  final bool isOpen;

  static bool openFrom(BuildContext context) =>
      !kIsWeb && MediaQuery.viewInsetsOf(context).bottom > 0;

  @override
  bool updateShouldNotify(KeyboardVisibility oldWidget) =>
      isOpen != oldWidget.isOpen;
}

/// Mobil uygulamada klavyenin hemen üstünde durur; dokununca klavye kapanır.
/// Sayısal klavyede "Bitti" tuşu olmadığı için gerekli.
class KeyboardDismissBar extends StatelessWidget {
  const KeyboardDismissBar({super.key});

  static bool isKeyboardOpen(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<KeyboardVisibility>()
          ?.isOpen ??
      KeyboardVisibility.openFrom(context);

  @override
  Widget build(BuildContext context) {
    if (!isKeyboardOpen(context)) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFEFE6D8),
        border: Border(top: BorderSide(color: AppColors.line, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
        icon: const Icon(
          Icons.keyboard_hide_rounded,
          size: 22,
          color: AppColors.forest,
        ),
        label: Text(
          'Klavyeyi kapat',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.forest,
          ),
        ),
      ),
    );
  }
}
