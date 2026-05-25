import 'package:flutter/material.dart';

class AppTheme {
  static const Color verde        = Color(0xFF2D5016);
  static const Color verdeClaro   = Color(0xFF7BBF3A);
  static const Color fondoClaro   = Color(0xFFF5F5F0);
  static const Color textoPrimario = Color(0xFF1A1A1A);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: verde,
      primary: verde,
      secondary: verdeClaro,
    ),
    scaffoldBackgroundColor: fondoClaro,
    appBarTheme: const AppBarTheme(
      backgroundColor: verde,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: verde,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: verde, width: 2),
      ),
    ),
  );
}
