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
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: EpuiciColors.primaire, width: 1.6),
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF14365C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      showDragHandle: true,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: EpuiciColors.secondaire.withValues(alpha: 0.6),
      height: 68,
      elevation: 8,
      shadowColor: Colors.black26,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (etats) => GoogleFonts.inter(
          fontSize: 11,
          fontWeight: etats.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: etats.contains(WidgetState.selected) ? EpuiciColors.primaire : Colors.grey.shade600,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (etats) => IconThemeData(
          color: etats.contains(WidgetState.selected) ? EpuiciColors.primaire : Colors.grey.shade600,
        ),
      ),
    ),
    // Transition "zoom" douce entre les pages, sur toutes les plateformes
    // (y compris la PWA, qui n'en avait pas).
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
      },
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: EpuiciColors.fond,
      foregroundColor: Colors.black87,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
  );
}
