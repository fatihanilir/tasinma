import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Ana renkler (HTML'den alındı)
  static const Color bg = Color(0xFFF4EFE6);
  static const Color ink = Color(0xFF1A241F);
  static const Color muted = Color(0xFF5D6B64);
  static const Color line = Color(0x1F1C3D32); // rgba(28, 61, 50, 0.12)
  static const Color card = Color(0xDBFFFCF7); // rgba(255, 252, 247, 0.86)
  static const Color forest = Color(0xFF1C3D32);
  static const Color forest2 = Color(0xFF2A5748);
  static const Color gold = Color(0xFFC9A46A);
  static const Color goldSoft = Color(0xFFEFE3CC);
  static const Color coral = Color(0xFFB85C38);
  static const Color white = Color(0xFFF8F3EA);

  // Gradient renkler
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment(-0.5, -1),
    end: Alignment(0.5, 1),
    colors: [Color(0xFF1C3D32), Color(0xFF2A5748), Color(0xFF3A6A58)],
  );

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF7F2EA), Color(0xFFEFE6D8)],
  );
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: GoogleFonts.outfit().fontFamily,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.light(
          primary: AppColors.forest,
          secondary: AppColors.gold,
          surface: AppColors.card,
          error: AppColors.coral,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppColors.forest,
            letterSpacing: -0.03 * 28,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: AppColors.line),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: false,
          border: InputBorder.none,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.08 * 12,
            color: AppColors.muted,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.forest,
            foregroundColor: AppColors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.goldSoft,
            foregroundColor: AppColors.forest,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            side: BorderSide.none,
            textStyle: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 40,
            fontWeight: FontWeight.w600,
            color: AppColors.forest,
            letterSpacing: -0.03 * 40,
          ),
          displayMedium: TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 34,
            fontWeight: FontWeight.w600,
            color: AppColors.forest,
            letterSpacing: -0.03 * 34,
          ),
          headlineLarge: TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppColors.forest,
            letterSpacing: -0.03 * 28,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: AppColors.forest,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.forest,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.ink,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.ink,
          ),
          bodySmall: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.muted,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.forest,
          ),
          labelMedium: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.08 * 12,
            color: AppColors.muted,
          ),
        ),
      );
}
