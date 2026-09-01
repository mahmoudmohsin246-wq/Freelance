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

## آخر تحديث: أكواد حضور من 6 أرقام
- كل موظف ولاعب دلوقتي ليه كود ثابت من 6 أرقام (بدل الـ ID الطويل بتاع Firebase) يستخدم في QR وفي الإدخال اليدوي.
- الكود بيتولد أول مرة تفتح شاشة الكود/QR بتاعت الشخص (من شاشة اللاعبين أو شاشة حضور الموظفين)، ومتضمن كمان في شاشة "اشتراكي" بتاعت اللاعب نفسه.
- الملفات الجديدة/المعدّلة الإضافية: `core/utils/attendance_code_generator.dart` (جديد)، `subscription_provider.dart`، `manager_subscriptions_screen.dart`، `my_subscription_screen.dart`، `staff_attendance_scanner_screen.dart`، `players_screen.dart`، `employee_attendance_screen_impl.dart`، و`firestore.rules` (قاعدة جديدة لـ collection اسمها `attendanceCodes`، وتعديل صلاحية تحديث `subscriptions` عشان الموظف يقدر يولّد كود ناقص من غير ما يعدّل باقي بيانات الاشتراك).
- **مهم**: لازم ترفع `firestore.rules` الجديد تاني على Firebase عشان الميزة دي تشتغل.
- الاشتراكات/الحسابات القديمة اللي اتعملت قبل التحديث ده مفيهاش كود لسه — هيتولدلها كود تلقائي أول مرة حد يفتح شاشة الـ QR بتاعتها.

## آخر تحديث: صور البروفايل بقت على Supabase Storage
- Firebase Storage اتشال خالص من المشروع (`firebase_storage` من `pubspec.yaml`). دلوقتي محتاجش خطة Blaze ولا فيزا خالص.
- Auth و Firestore (كل البيانات التانية) لسه على Firebase زي ما هي بالظبط — التغيير ده بخص صور البروفايل بس.
- ملف جديد: `lib/core/services/supabase_storage_service.dart`.
- `main.dart` بقى بيعمل `Supabase.initialize(...)` بالـ URL والمفتاح اللي بعتهملي.

### خطوات لازم تعملها على Supabase Dashboard (مرة واحدة بس):
1. من Storage، اعمل bucket اسمه بالظبط `avatars`.
2. من Storage → Policies، ضيف الـ policies دي (SQL Editor أسهل، الصق الكود ده ورن):

```sql
create policy "Allow anon uploads to avatars"
on storage.objects for insert
to anon
with check (bucket_id = 'avatars');

create policy "Allow anon updates to avatars"
on storage.objects for update
to anon
using (bucket_id = 'avatars');

create policy "Allow public read access to avatars"
on storage.objects for select
to public
using (bucket_id = 'avatars');
```

مهم: التطبيق مبيسجلش دخول على Supabase نفسه (لسه بيستخدم Firebase Auth للدخول)، فأي طلب لـ Supabase بيتبعت كـ "anon" — عشان كده الـ policies فوق بتسمح لـ `anon` تحديدًا، مش `authenticated`. من غيرها هيطلعلك خطأ صلاحيات (403) وقت رفع الصورة.

3. `flutter pub get` عشان يجيب مكتبة `supabase_flutter`.

## آخر تحديث: الماليات (الإيرادات/المصروفات) بقت على Firestore
- نفس مشكلة اللاعبين بالظبط كانت موجودة في `financial_provider.dart` — كل الإيرادات والمصروفات كانت بتتخزن محليًا بس (SharedPreferences)، فمكنش بيظهر إيراد الاشتراكات في شاشة "الماليات والمصروفات" لو الجلسة/الجهاز اتغير.
- دلوقتي كل حركة مالية (إيراد أو مصروف) بتتسجل على Firestore في collection اسمها `transactions`.
- `main_layout.dart` بقى بيعمل reload لبيانات الماليات بعد ما تسجيل الدخول يخلص (نفس إصلاح اللاعبين).
- `firestore.rules` — أضفت قاعدة جديدة: بيانات `transactions` متاحة بس للمانيجر والموظف (staff)، مش للاعبين خالص.
- **لازم ترفع `firestore.rules` الجديد تاني على Firebase.**
