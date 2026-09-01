import 'package:flutter/material.dart';

class AppTheme {
  static const Color scaffoldBg = Color(0xFF0F172A); // Dark Navy Background
  static const Color drawerBg = Color(0xFF111827);   // Dark Sidebar Background
  static const Color cardBg = Color(0xFF1E293B);     // Card Background
  static const Color primaryBlue = Color(0xFF38BDF8); // Bright Light Blue
  static const Color accentGreen = Color(0xFF10B981); // Emerald Green
  static const Color textColor = Color(0xFFF8FAFC);    // Off-white text
  static const Color subTextColor = Color(0xFF94A3B8); // Grayish subtitle


  static const Color lightScaffoldBg = Color(0xFFF4F7FB);
  static const Color lightDrawerBg = Color(0xFFFFFFFF);
  static const Color lightCardBg = Color(0xFFFFFFFF);
  static const Color lightPrimaryBlue = Color(0xFF0284C7);
  static const Color lightAccentGreen = Color(0xFF059669);
  static const Color lightTextColor = Color(0xFF0F172A);
  static const Color lightSubTextColor = Color(0xFF64748B);
  static const Color lightBorderColor = Color(0xFFE2E8F0);

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: primaryBlue,
      cardColor: cardBg,
      canvasColor: drawerBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldBg,
        elevation: 0,
        titleTextStyle: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: primaryBlue),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: drawerBg,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: scaffoldBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: lightScaffoldBg,
      primaryColor: lightPrimaryBlue,
      cardColor: lightCardBg,
      canvasColor: lightDrawerBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: lightPrimaryBlue,
        brightness: Brightness.light,
        primary: lightPrimaryBlue,
        secondary: lightAccentGreen,
        surface: lightCardBg,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightScaffoldBg,
        elevation: 0,
        titleTextStyle: TextStyle(color: lightTextColor, fontSize: 18, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: lightPrimaryBlue),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: lightDrawerBg,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      cardTheme: CardThemeData(
        color: lightCardBg,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: lightBorderColor),
        ),
      ),
    );
  }
}