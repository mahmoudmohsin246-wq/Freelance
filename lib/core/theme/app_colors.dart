import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/theme_provider.dart';

class AppColors {
  final bool isDark;

  const AppColors(this.isDark);

  static AppColors of(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    return AppColors(isDark);
  }


  static const Color primary = Color(0xFF10B981);
  static const Color primaryLight = Color(0xFF34D399);
  static const Color accent = Color(0xFF34D399);
  static const Color danger = Color(0xFFEF4444);

  static const Color bgLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFF4F6F4);
  static const Color borderLight = Color(0xFFE5E7EB);

  static const Color bgDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF1E1E1E);
  static const Color borderDark = Color(0xFF2D2D2D);


  Color get primaryBlue => isDark ? primaryLight : primary;
  Color get scaffoldBg => isDark ? bgDark : bgLight;
  Color get drawerBg => isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF);
  Color get cardBg => isDark ? cardDark : cardLight;
  Color get primaryColor => isDark ? primaryLight : primary;
  Color get accentGreen => isDark ? primaryLight : primary;
  Color get textColor => isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111827);
  Color get subTextColor => isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);
  Color get borderColor => isDark ? borderDark : borderLight;
  Color get gold => isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
  Color get onPrimary => isDark ? const Color(0xFF121212) : const Color(0xFFFFFFFF);
}