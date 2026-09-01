import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

const String _contactPhone1 = '01558470814';
const String _contactPhone2 = '01027772480';

class AboutAppScreenImpl extends StatelessWidget {
  const AboutAppScreenImpl({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    return Container(
      color: colors.scaffoldBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors.primaryBlue, colors.accentGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.sports_soccer_rounded, color: Colors.white, size: 36),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  loc.translate('appName'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${loc.translate('version')} 1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.subTextColor, fontSize: 12),
                ),
                const SizedBox(height: 20),

                Text(
                  loc.translate('aboutAppBody'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.subTextColor, fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 24),

                Text(
                  loc.translate('ourFeatures'),
                  style: TextStyle(color: colors.textColor, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _featureTile(colors, Icons.storefront_outlined, loc.translate('featureBranches')),
                _featureTile(colors, Icons.groups_outlined, loc.translate('featurePlayers')),
                _featureTile(colors, Icons.account_balance_wallet_outlined, loc.translate('featureFinance')),
                _featureTile(colors, Icons.qr_code_scanner_rounded, loc.translate('featureAttendance')),
                _featureTile(colors, Icons.admin_panel_settings_outlined, loc.translate('featureTeam')),
                const SizedBox(height: 24),

                _linkTile(
                  context,
                  colors,
                  Icons.privacy_tip_outlined,
                  loc.translate('privacyPolicy'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const _LegalTextScreen(kind: _LegalKind.privacy)),
                  ),
                ),
                _linkTile(
                  context,
                  colors,
                  Icons.article_outlined,
                  loc.translate('termsAndConditions'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const _LegalTextScreen(kind: _LegalKind.terms)),
                  ),
                ),
                _contactTile(context, colors, loc),

                const SizedBox(height: 24),
                Center(
                  child: Text(
                    loc.translate('developedBy'),
                    style: TextStyle(color: colors.subTextColor, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureTile(AppColors colors, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              // تم استبدال withOpacity بـ withValues لتوافق مع الإصدارات الأحدث
              color: colors.primaryBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: colors.primaryBlue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: colors.textColor, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _linkTile(BuildContext context, AppColors colors, IconData icon, String title,
      {required VoidCallback onTap}) {
    return Card(
      color: colors.cardBg,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: colors.subTextColor),
        title: Text(title, style: TextStyle(color: colors.textColor, fontSize: 14)),
        trailing: Icon(Icons.chevron_left_rounded, color: colors.subTextColor),
        onTap: onTap,
      ),
    );
  }

  Widget _contactTile(BuildContext context, AppColors colors, AppLocalizations loc) {
    return Card(
      color: colors.cardBg,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.mail_outline, color: colors.subTextColor),
        title: Text(loc.translate('contactUs'), style: TextStyle(color: colors.textColor, fontSize: 14)),
        subtitle: Text(
          '$_contactPhone1 - $_contactPhone2',
          style: TextStyle(color: colors.primaryBlue, fontSize: 13),
          textDirection: TextDirection.ltr,
        ),
        trailing: Icon(Icons.chevron_left_rounded, color: colors.subTextColor),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const _LegalTextScreen(kind: _LegalKind.contact)),
        ),
      ),
    );
  }
}

enum _LegalKind { privacy, terms, contact }

class _LegalTextScreen extends StatelessWidget {
  final _LegalKind kind;
  const _LegalTextScreen({required this.kind});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isArabic = loc.locale.languageCode == 'ar';
    final colors = AppColors.of(context);

    late String title;
    late String body;

    switch (kind) {
      case _LegalKind.privacy:
        title = loc.translate('privacyPolicyTitle');
        body = isArabic ? _privacyAr : _privacyEn;
        break;
      case _LegalKind.terms:
        title = loc.translate('termsAndConditionsTitle');
        body = isArabic ? _termsAr : _termsEn;
        break;
      case _LegalKind.contact:
        title = loc.translate('contactUsTitle');
        body = (isArabic ? _contactAr : _contactEn)
            .replaceAll('{phone}', '$_contactPhone1 - $_contactPhone2');
        break;
    }

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: colors.scaffoldBg,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.primaryBlue),
        title: Text(title, style: TextStyle(color: colors.textColor)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          body,
          style: TextStyle(color: colors.subTextColor, fontSize: 14, height: 1.8),
        ),
      ),
    );
  }
}

const String _privacyAr = '''
آخر تحديث: 2026

نحن في نظام إدارة الأكاديميات الرياضية نحترم خصوصيتك، وتوضح هذه السياسة نوع البيانات التي نجمعها وكيف نستخدمها.

1. البيانات التي نجمعها
نجمع البيانات التي تدخلها بنفسك عند إنشاء الحساب: الاسم، البريد الإلكتروني، رقم الهاتف، واسم الأكاديمية. كما نخزّن بيانات اللاعبين والمشتركين والمعاملات المالية التي تُدخلها داخل التطبيق.

2. كيف نستخدم بياناتك
تُستخدم البيانات فقط لتشغيل خدمات التطبيق: إدارة الفروع، متابعة الاشتراكات، تسجيل الحضور، وإعداد التقارير المالية. لا نبيع بياناتك لأي طرف ثالث.

3. تخزين البيانات
تُخزَّن البيانات محلياً على جهازك، ولا تُرسل إلى خوادم خارجية في هذا الإصدار من التطبيق.

4. حقوقك
يمكنك تعديل أو حذف بياناتك في أي وقت من خلال إعدادات حسابك، بما في ذلك حذف الحساب نهائياً من القائمة الجانبية.

5. خصوصية الأطفال
قد يحتوي التطبيق على بيانات لاعبين قاصرين يُدخلها أولياء الأمور أو المدربون؛ هذه البيانات تُعامل بنفس مستوى الحماية المذكور أعلاه، ونوصي بعدم إدخال بيانات حساسة غير ضرورية.

6. التعديلات على هذه السياسة
قد تُحدَّث هذه السياسة من وقت لآخر، وسيتم إعلامك بأي تغييرات جوهرية داخل التطبيق.

7. التواصل
لأي استفسار بخصوص الخصوصية، يمكنك التواصل معنا من خلال صفحة "اتصل بنا".
''';

const String _privacyEn = '''
Last updated: 2026

At the Sports Academy Management System, we respect your privacy. This policy explains what data we collect and how we use it.

1. Data We Collect
We collect the data you provide when creating an account: name, email, phone number, and academy name. We also store player, subscriber, and financial transaction data you enter within the app.

2. How We Use Your Data
Your data is used solely to operate the app's services: managing branches, tracking subscriptions, recording attendance, and generating financial reports. We do not sell your data to third parties.

3. Data Storage
Data is stored locally on your device and is not sent to external servers in this version of the app.

4. Your Rights
You can edit or delete your data at any time from your account settings, including permanently deleting your account from the side menu.

5. Children's Privacy
The app may contain data about minor players entered by parents or coaches. This data is treated with the same protection described above, and we recommend not entering unnecessary sensitive information.

6. Changes to This Policy
This policy may be updated from time to time. You will be notified of any material changes within the app.

7. Contact
For any privacy inquiries, you can reach us through the "Contact Us" page.
''';

const String _termsAr = '''
آخر تحديث: 2026

بستخدامك لتطبيق نظام إدارة الأكاديميات الرياضية، فإنك توافق على الشروط والأحكام التالية.

1. قبول الشروط
استخدامك للتطبيق يعني موافقتك الكاملة على هذه الشروط. إذا كنت لا توافق عليها، يرجى التوقف عن استخدام التطبيق.

2. الحساب والمسؤولية
أنت مسؤول عن الحفاظ على سرية بيانات دخولك، وعن كل نشاط يتم من خلال حسابك. يُرجى استخدام كلمة مرور قوية وعدم مشاركتها مع أي شخص آخر.

3. الأدوار والصلاحيات
يمنح التطبيق صلاحيات مختلفة حسب نوع الحساب (مدير، موظف، متدرب). يتحمل صاحب حساب المدير مسؤولية منح صلاحيات الإدارة للحسابات الأخرى داخل أكاديميته.

4. الاشتراكات والدفع
بعض ميزات التطبيق قد تكون متاحة فقط ضمن باقات مدفوعة (مثل باقة Pro). الأسعار والمزايا المعروضة داخل التطبيق قابلة للتغيير مع إشعار مسبق للمستخدمين.

5. الاستخدام المقبول
يُمنع استخدام التطبيق لأي غرض غير قانوني، أو إدخال بيانات مضللة أو مسيئة لأي طرف آخر.

6. الملكية الفكرية
جميع عناصر التصميم والمحتوى داخل التطبيق مملوكة لمطوّري التطبيق، ولا يجوز نسخها أو إعادة استخدامها دون إذن.

7. إنهاء الحساب
يحق لك حذف حسابك في أي وقت. كما نحتفظ بالحق في تعليق أو إنهاء أي حساب يخالف هذه الشروط.

8. حدود المسؤولية
يُقدَّم التطبيق "كما هو" دون أي ضمانات، ولا نتحمل مسؤولية أي خسائر ناتجة عن استخدامه.

9. التعديلات على الشروط
قد تُحدَّث هذه الشروط من وقت لآخر، واستمرارك في استخدام التطبيق بعد التحديث يُعد موافقة على الشروط الجديدة.

10. التواصل
لأي استفسار بخصوص هذه الشروط، يمكنك التواصل معنا من خلال صفحة "اتصل بنا".
''';

const String _termsEn = '''
Last updated: 2026

By using the Sports Academy Management System app, you agree to the following terms and conditions.

1. Acceptance of Terms
Using the app means you fully accept these terms. If you do not agree, please stop using the app.

2. Account & Responsibility
You are responsible for keeping your login credentials confidential and for all activity under your account. Please use a strong password and do not share it with anyone.

3. Roles & Permissions
The app grants different permissions based on account type (manager, employee, trainee). The manager account holder is responsible for granting management permissions to other accounts within their academy.

4. Subscriptions & Payment
Some app features may only be available under paid plans (such as the Pro package). Prices and features shown in the app are subject to change with prior notice to users.

5. Acceptable Use
The app may not be used for any illegal purpose, or to enter misleading or abusive data about any other party.

6. Intellectual Property
All design elements and content within the app are owned by the app developers and may not be copied or reused without permission.

7. Account Termination
You may delete your account at any time. We also reserve the right to suspend or terminate any account that violates these terms.

8. Limitation of Liability
The app is provided "as is" without any warranties, and we are not liable for any losses resulting from its use.

9. Changes to Terms
These terms may be updated from time to time. Continued use of the app after an update constitutes acceptance of the new terms.

10. Contact
For any inquiries regarding these terms, you can reach us through the "Contact Us" page.
''';

const String _contactAr = '''
يسعدنا تواصلك معنا لأي استفسار أو مشكلة تقنية أو اقتراح لتحسين التطبيق.

رقم التواصل: {phone}

يمكنك التواصل معنا هاتفياً أو عبر واتساب على نفس الرقم، وسيقوم فريق الدعم بالرد عليك في أقرب وقت ممكن.
''';

const String _contactEn = '''
We'd love to hear from you for any inquiry, technical issue, or suggestion to improve the app.

Contact Number: {phone}

You can reach us by phone or WhatsApp on the same number, and our support team will respond as soon as possible.
''';