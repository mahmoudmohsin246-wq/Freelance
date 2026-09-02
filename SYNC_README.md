# مزامنة آخر مشروع بعتهولي

راجعت الملفات اللي بعتهالي (lib.rar + firestore.rules + pubspec.yaml) قارنتها بكل التعديلات اللي عملناها مع بعض من الأول، ولقيت إن معظمها موجود ومظبوط 👍، وباقي بس آخر جولة مراجعة (اللي فيها الـ crash bug + الفروع + الدعوات) كانت ناقصة. ده اللي رجّعته:

## الملفات اللي اتغيّرت في الباتش ده بس
- `lib/presentation/providers/branches_provider.dart` — رجّعته لنسخة Firestore (كان لسه محلي بس عندك).
- `lib/presentation/providers/invitations_provider.dart` — رجّعته لنسخة Firestore.
- `lib/presentation/providers/auth_provider.dart` — رجّعت منطق التحقق من الدعوة جوه `register()`.
- `lib/presentation/screens/auth/register_screen.dart` — بسّطته (مبقاش بيدور على الدعوة بنفسه).
- `lib/presentation/screens/dashboard/main_layout.dart` — شلت زرار "Switch Workspace" (كان بيعمل crash)، وضفت إعادة تحميل للفروع والدعوات بعد تسجيل الدخول.
- `firestore.rules` — رجّعت الـ 3 قواعد الناقصة (`branches`, `appSettings`, `invitations`) — الباقي كله كان موجود وصح.

## حاجات ما لمستهاش خالص (شغالة تمام زي ما هي)
- `login_screen.dart` (اللوجو بتاعك)
- `about_screen_impl.dart` (الرقمين الثابتين بتوع التواصل)
- `settings_provider.dart` — سبته زي ما هو، لأنه بقى مش مستخدم أصلاً (بما إن أرقام التواصل بقت ثابتة في الكود مباشرة، مش محتاج Firestore خالص). لو حبيت تفعّل تعديل الأرقام من داخل التطبيق تاني في المستقبل، قولّي وقتها.
- `pubspec.yaml` — بتاعك مظبوط 100% زي ما بعتهولي (فيه `supabase_flutter`، مفيهوش `firebase_storage`).

## اللي تعمله دلوقتي
1. استبدل الملفات الستة دي في مشروعك بنسخة الزيب ده.
2. ارفع `firestore.rules` الجديد على Firebase.
3. `flutter clean && flutter pub get && flutter run`.
4. اختبار سريع أخير: زرار "Switch Workspace" اتشال، إضافة فرع تظهر لحساب تاني، وإرسال دعوة يحدد الـ role صح بعد التسجيل.
