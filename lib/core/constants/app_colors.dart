import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF2563EB); // Vibrant Blue
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFF60A5FA);
  
  static const Color accent = Color(0xFF10B981); // Emerald Green
  static const Color accentOrange = Color(0xFFF59E0B);
  
  // Backgrounds
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardLight = Colors.white;
  static const Color bgDark = Color(0xFF0F172A);
  static const Color cardDark = Color(0xFF1E293B);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Borders & Dividers
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
