import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../auth/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // مؤقت زمني لمدة 3 ثوانٍ ثم الانتقال التلقائي لشاشة الـ AuthGate
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthGate()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // 1. خلفية داكنة ذكية تملأ الفراغات الجانبية على اللاب توب والتابلت
          Container(
            color: const Color(0xFF0A0E17), // لون مستوحى من أطراف صورة الملعب
          ),

          // 2. عرض صورة الكرة والملعب بالكامل بدون أي قص أو زوم خاطئ
          Center(
            child: Image.asset(
              'assets/splash_bg.png', // تأكد أن صورة الملعب موجودة بهذا الاسم في مجلد assets
              fit: BoxFit.contain,    // يجبر الصورة على الظهور كاملة بكافة تفاصيلها
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // 3. طبقة تظليل خفيفة لإعطاء طابع سينمائي وضمان وضوح العناصر
          Container(
            color: Colors.black.withOpacity(0.15),
          ),

          // 4. المحتوى العلوي والسفلي (اسم التطبيق ومؤشر التحميل)
          SafeArea(
            child: Stack(
              children: [
                // اسم التطبيق في الثلث العلوي من الشاشة لمنع تغطية الكرة
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.12,
                  left: 0,
                  right: 0,
                  child: const Center(
                    child: Text(
                      'Sports Academy App',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // لون أبيض ثابت يتماشى مع أجواء الملعب
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            blurRadius: 12.0,
                            color: Colors.black87,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // مؤشر التحميل الدائري باللون الأخضر المميز في الأسفل
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: colors.primaryColor, // الأخضر الرياضي الخاص بهويتك
                      strokeWidth: 3.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
