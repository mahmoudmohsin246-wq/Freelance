import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/financial_provider.dart';
import 'presentation/providers/subscription_provider.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/providers/branches_provider.dart';
import 'presentation/providers/attendance_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/invitations_provider.dart';
import 'presentation/providers/activity_log_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'core/localization/app_localizations.dart';
import 'presentation/screens/splash/splash_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Supabase is used ONLY for Storage (profile pictures). Auth and all app
  // data stay on Firebase/Firestore, unchanged.
  await Supabase.initialize(
    url: 'https://twgcnijtlmcjvuwbyguc.supabase.co',
    anonKey: 'sb_publishable_ITD43wcgrA0QlY_eyYk-Og_qWfAlPjg',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FinancialProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => BranchesProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => InvitationsProvider()),
        ChangeNotifierProvider(create: (_) => ActivityLogProvider()),
      ],
      child: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (context, localeProv, themeProv, _) {
          return MaterialApp(
            title: 'Sports Academy App',
            debugShowCheckedModeBanner: false,
            themeMode: themeProv.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            locale: localeProv.locale,
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),
            ],
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const SplashScreen(), 
          );
        },
      ),
    );
  }
}
