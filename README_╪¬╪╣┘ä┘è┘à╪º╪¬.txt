تعليمات وضع الملفات — النسخة دي شغالة بالكامل من Supabase (من غير Firebase
Cloud Functions، من غير Blaze plan، من غير أي فلوس أو بطاقة).

=== الملفات ===

1) supabase/sql/academy_names_setup.sql   [ملف جديد]
   ده مش بيتحط في المشروع وميتعملوش deploy -- تفتحه، تنسخ اللي جواه، وتلزقه
   وتشغّله مرة واحدة بس من:
   Supabase Dashboard -> اختار مشروعك -> SQL Editor -> New query -> الصق -> Run

2) supabase/functions/sync-academy-names/index.ts   [ملف جديد]
   حطه بالظبط في: supabase/functions/sync-academy-names/index.ts

3) supabase/config.toml   [استبدال]
   ده نفس ملفك الأصلي + إضافة تعريف الـ function الجديدة في الآخر.
   استبدل بيه: supabase/config.toml

4) lib/presentation/providers/auth_provider.dart   [استبدال]
   نفس الملف الأصلي، اتغيرت جواه:
   - الـ imports فوق (إضافة supabase_flutter + http + dart:convert/async)
   - دالة fetchAcademyNames() بقت بتقرا من Supabase بدل Firestore
   - إضافة دالتين جداد: _syncAcademyNamesToSupabase و backfillAcademyNamesToSupabaseOnce
   - سطر واحد إضافي جوه register() بيبعت اسم الأكاديمية لـ Supabase أول
     ما مدير جديد يسجل حساب
   استبدل بيه: lib/presentation/providers/auth_provider.dart

=== خطوات التنفيذ بالترتيب ===

1. شغّل ملف الـ SQL (خطوة 1 فوق) -- ده بيعمل الجدول ويحميه.

2. من مجلد المشروع في PowerShell:
   supabase functions deploy sync-academy-names

   (لو أول مرة تستخدم Supabase CLI من الجهاز ده، ممكن يطلب منك تعمل
   login الأول:  supabase login   وبعدين تربط المشروع:
   supabase link --project-ref twgcnijtlmcjvuwbyguc)

3. اعمل flutter pub get عشان يتأكد كل الحزم موجودة (http و supabase_flutter
   أصلاً موجودين في pubspec.yaml من قبل).

4. شغّل التطبيق. سجّل دخول بأي حساب مدير/موظف موجود عندك بالفعل
   (أي حساب staff، مش لازم يكون هو صاحب الأكاديمية).

5. عشان تنقل الأكاديميات الموجودة من قبل لـ Supabase (مرة واحدة بس):
   مؤقتًا، ضيف السطر ده في أي مكان بيتنفذ بعد تسجيل الدخول بنجاح
   (مثلاً جوه initState بتاع main_layout.dart أو أي شاشة بعد اللوجين):

   Provider.of<AuthProvider>(context, listen: false).backfillAcademyNamesToSupabaseOnce();

   شغّل التطبيق مرة، سيبه لحظة يشتغل، وبعدين امسح السطر ده تاني
   (مش هتحتاجه غير مرة واحدة).

6. تأكد إن البيانات وصلت: من Supabase Dashboard -> Table Editor ->
   academy_names -- المفروض تلاقي الأسماء موجودة.

7. جرب شاشة "إنشاء حساب جديد" -> دوس على حقل الأكاديمية -> المفروض
   الأسماء تظهر دلوقتي.

من هنا وبعد كده، أي مدير جديد يسجل حساب، اسم أكاديميته هيتضاف لنفس
الجدول أوتوماتيك -- من غير أي تدخل منك.

=== ملاحظة عن التخزين ===
كل حاجة هنا سحابية 100%: بيانات المستخدمين والأكاديميات في Firestore
زي ما هي، وقائمة أسماء الأكاديميات العامة دي بقت في Supabase (نفس
الحساب اللي بيستخدمه التطبيق أصلاً لصور البروفايل). مفيش أي تخزين
محلي على الجهاز.
