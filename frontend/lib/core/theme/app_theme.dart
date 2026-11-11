import 'package:flutter/material.dart';

/// Central theme specification for SmartPark.
///
/// Uses Material 3 design tokens with a high-contrast, professional palette.
///
/// // ponytail: standard ThemeData.from colorScheme; native Material 3 widgets
class AppTheme {
  const AppTheme._();

  // Primary brand palette
  static const Color primaryBlue = Color(0xFF1E40AF);
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  // Status indicator colors
  static const Color statusAvailable = Color(0xFF16A34A);
  static const Color statusOccupied = Color(0xFFDC2626);
  static const Color statusReserved = Color(0xFFD97706);
  static const Color statusMaintenance = Color(0xFF64748B);

  /// Builds the light theme for the application.
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
      surface: surfaceLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: surfaceLight,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
