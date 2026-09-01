# التعديلات اللي اتعملت

فك ضغط هذا الملف وانسخ الملفات جوه مجلد مشروعك (نفس المسارات بالظبط) عشان تستبدل القديمة.

## الملفات المعدّلة/الجديدة
- `lib/presentation/providers/attendance_provider.dart` — الحضور بقى بيتسجل على Firestore بدل SharedPreferences.
- `lib/presentation/providers/auth_provider.dart` — إضافة `fetchUserById` بس (باقي الملف زي ما هو).
- `lib/presentation/screens/attendance/person_attendance_screen.dart` — **جديد**: شاشة التقويم وبيانات الشخص.
- `lib/presentation/screens/players/attendance_scanner_screen.dart` — سكانر حضور اللاعبين، بيسجل على Firestore.
- `lib/presentation/screens/players/players_screen.dart` — دوس على أي لاعب يفتحله تقويم الحضور.
- `lib/presentation/screens/employees/staff_attendance_scanner_screen.dart` — سكانر حضور الموظفين، بيسجل على Firestore.
- `lib/presentation/screens/employees/employee_attendance_screen_impl.dart` — دوس على أي موظف يفتحله تقويم الحضور.
- `lib/core/localization/app_localizations.dart` — ترجمات جديدة بس (باقي الملف زي ما هو).
- `firestore.rules` — تحديث قواعد الأمان عشان تتوافق مع شكل بيانات الحضور الجديد.

## قبل ما تشغّل التطبيق
1. تأكد إن `cloud_firestore` شغال (هو أصلاً موجود في `pubspec.yaml`).
2. ارفع `firestore.rules` الجديد على مشروع Firebase بتاعك (Firebase Console → Firestore → Rules، أو `firebase deploy --only firestore:rules` لو معاك Firebase CLI).
3. شغّل `flutter pub get` ثم `flutter run` وجرّب:
   - تسجّل حضور موظف من شاشة "حضور الموظفين".
   - تسجّل حضور لاعب من شاشة "اللاعبين" (لازم يكون عنده اشتراك متربط بحساب Firebase حقيقي عن طريق شاشة إدارة الاشتراكات، مش الإضافة السريعة).
   - تدوس على اسم أي موظف/لاعب وتشوف التقويم وبياناته.

## ملاحظة
اللاعبين اللي اتضافوا عن طريق زرار "إضافة لاعب" السريع في شاشة اللاعبين (مش عن طريق البحث بالإيميل في شاشة الاشتراكات) معندهمش حساب Firebase مرتبط، فمش هيظهرلهم تقويم — هيظهر رسالة إنه معندوش حساب مرتبط. لو عايز الميزة دي تشتغل مع كل اللاعبين، محتاج تخلي كل الاعبين يتضافوا عن طريق ربط حساب حقيقي بدل الإضافة السريعة.
