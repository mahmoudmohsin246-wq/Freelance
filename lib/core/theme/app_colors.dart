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

  // ألوان ثابتة (Static) ليقرأها ملف AppTheme بدون BuildContext
  static const Color primary = Color(0xFF10B981);       // أخضر عشبي أساسي
  static const Color primaryLight = Color(0xFF34D399);  // أخضر نيون مضيء
  static const Color accent = Color(0xFF34D399);       // اللون المساعد
  static const Color danger = Color(0xFFEF4444);       // لون الأخطاء والإنذارات

  static const Color bgLight = Color(0xFFFFFFFF);      // خلفية الفاتح الأساسية
  static const Color cardLight = Color(0xFFF4F6F4);    // خلفية كروت الفاتح
  static const Color borderLight = Color(0xFFE5E7EB);  // حدود الفاتح

  static const Color bgDark = Color(0xFF121212);       // خلفية الداكن الأساسية
  static const Color cardDark = Color(0xFF1E1E1E);     // خلفية كروت الداكن
  static const Color borderDark = Color(0xFF2D2D2D);   // حدود الداكن

  // ألوان ديناميكية (Getters) تم ربطها بالأسماء القديمة لضمان عدم حدوث خطأ في الشاشات
  Color get primaryBlue => isDark ? primaryLight : primary; // تم ربط الاسم القديم بالأخضر الجديد
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
