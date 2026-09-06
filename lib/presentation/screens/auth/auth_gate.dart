import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../dashboard/main_layout.dart';
import 'login_screen.dart';
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final colors = AppColors.of(context);
    if (authProv.isCheckingSession) {
      return Scaffold(
        backgroundColor: colors.scaffoldBg,
        body: Center(
          child: CircularProgressIndicator(color: colors.primaryBlue),
        ),
      );
    }
    if (authProv.isAuthenticated) {
      return const MainLayout();
    }
    return const LoginScreen();
  }
}