import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema de diseño de Ratatui.
///
/// Paleta cálida y botánica pensada para una app de recetas y bienestar:
/// verde bosque como color de marca, mostaza como acento de calidez/acción,
/// y un fondo lino en vez del típico gris frío de las apps genéricas.
class AppTheme {
  // ── Paleta ────────────────────────────────────────────────────────────
  static const Color bosque   = Color(0xFF1B4332); // primario
  static const Color musgo    = Color(0xFF52796F); // secundario
  static const Color mostaza  = Color(0xFFD9A441); // acento cálido / CTA
  static const Color lino     = Color(0xFFF6F4EC); // fondo
  static const Color carbon   = Color(0xFF22261F); // texto principal
  static const Color grisTexto = Color(0xFF6B7268); // texto secundario
  static const Color borde    = Color(0xFFE4E0D4);
  static const Color salvia   = Color(0xFFEAF1E4); // fondo de tiles/badges

  static const double radioTarjeta = 22;
  static const double radioChico   = 14;

  static const List<BoxShadow> sombraSuave = [
    BoxShadow(
      color: Color(0x1A1B4332),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  // ── Tipografía ────────────────────────────────────────────────────────
  static TextTheme get _textTheme {
    final base = GoogleFonts.manropeTextTheme();
    return base.copyWith(
      displayLarge: GoogleFonts.fraunces(
          fontSize: 32, fontWeight: FontWeight.w600, color: carbon, height: 1.15),
      displayMedium: GoogleFonts.fraunces(
          fontSize: 26, fontWeight: FontWeight.w600, color: carbon, height: 1.2),
      headlineMedium: GoogleFonts.fraunces(
          fontSize: 22, fontWeight: FontWeight.w600, color: carbon),
      headlineSmall: GoogleFonts.fraunces(
          fontSize: 18, fontWeight: FontWeight.w600, color: carbon),
      titleMedium: GoogleFonts.manrope(
          fontSize: 15, fontWeight: FontWeight.w700, color: carbon),
      bodyLarge: GoogleFonts.manrope(fontSize: 15, color: carbon, height: 1.5),
      bodyMedium: GoogleFonts.manrope(fontSize: 13.5, color: carbon, height: 1.45),
      labelLarge: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700),
      labelSmall: GoogleFonts.manrope(
          fontSize: 11, fontWeight: FontWeight.w600, color: grisTexto, letterSpacing: 0.3),
    );
  }

  /// Estilo "eyebrow": etiqueta pequeña en mayúsculas con tracking, usado
  /// como firma tipográfica recurrente sobre títulos de sección.
  static TextStyle get eyebrow => GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: musgo,
      );

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.manrope().fontFamily,
    textTheme: _textTheme,
    colorScheme: ColorScheme.fromSeed(
      seedColor: bosque,
      primary: bosque,
      secondary: mostaza,
      surface: Colors.white,
      error: const Color(0xFFB3261E),
    ),
    scaffoldBackgroundColor: lino,
    appBarTheme: AppBarTheme(
      backgroundColor: lino,
      foregroundColor: carbon,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: GoogleFonts.fraunces(
          fontSize: 20, fontWeight: FontWeight.w600, color: carbon),
      iconTheme: const IconThemeData(color: bosque),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radioTarjeta)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: bosque,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        textStyle: GoogleFonts.manrope(fontSize: 15.5, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: bosque,
        textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: salvia,
      selectedColor: salvia,
      labelStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: carbon),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: GoogleFonts.manrope(color: grisTexto),
      labelStyle: GoogleFonts.manrope(color: grisTexto, fontSize: 13.5),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: borde),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: borde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: bosque, width: 1.6),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: bosque,
      unselectedItemColor: grisTexto,
      selectedLabelStyle: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w700),
      unselectedLabelStyle: GoogleFonts.manrope(fontSize: 11.5),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(color: borde, thickness: 1),
  );
}
