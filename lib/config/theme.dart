import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EpuiciColors {
  // Couleurs tirées du logo EPUICI (globe bleu / vert)
  static const Color primaire = Color(0xFF0B5CA8);
  static const Color primaireClair = Color(0xFF2B7BC4);
  static const Color accent = Color(0xFF2F7D32);
  static const Color secondaire = Color(0xFFA9D1F2);
  static const Color fond = Color(0xFFF5F8FB);
}

class EpuiciTheme {
  static ThemeData clair = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: EpuiciColors.fond,
    colorScheme: ColorScheme.fromSeed(
      seedColor: EpuiciColors.primaire,
      primary: EpuiciColors.primaire,
      secondary: EpuiciColors.accent,
      tertiary: EpuiciColors.secondaire,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      titleLarge: GoogleFonts.baloo2(fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.baloo2(fontWeight: FontWeight.w600),
      headlineSmall: GoogleFonts.baloo2(fontWeight: FontWeight.w700),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: EpuiciColors.secondaire,
        foregroundColor: EpuiciColors.primaire,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: EpuiciColors.fond,
      foregroundColor: Colors.black87,
      elevation: 0,
      centerTitle: false,
    ),
  );
}
