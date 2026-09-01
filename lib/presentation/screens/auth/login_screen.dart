import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late AppColors _colors;
  Color get scaffoldBg => _colors.scaffoldBg;
  Color get cardBg => _colors.cardBg;
  Color get primaryBlue => _colors.primaryBlue;
  Color get accentGreen => _colors.accentGreen;
  Color get textColor => _colors.textColor;
  Color get subTextColor => _colors.subTextColor;
  Color get borderColor => _colors.borderColor;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations loc) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProv.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    if (!success && authProv.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.translate(authProv.errorMessage!), style: GoogleFonts.inter()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final loc = AppLocalizations.of(context);
    final localeProv = context.watch<LocaleProvider>();
    _colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => context.read<ThemeProvider>().toggleTheme(),
                    icon: Icon(
                      context.watch<ThemeProvider>().isDarkMode
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      color: primaryBlue,
                    ),
                    tooltip: loc.translate('toggleTheme'),
                  ),
                  TextButton.icon(
                    onPressed: () => localeProv.toggleLanguage(),
                    icon: Icon(Icons.language, color: primaryBlue, size: 20),
                    label: Text(
                      localeProv.isArabic ? 'English' : 'العربية',
                      style: GoogleFonts.inter(color: primaryBlue, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                    Center(
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            'assets/logo_1.jpeg',
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      loc.translate('welcomeBack'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: textColor,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.translate('loginSubtitle'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: subTextColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 36),

                    _buildLabel(loc.translate('emailLabel')),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _emailController,
                      hint: 'example@email.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return loc.translate('enterEmail');
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return loc.translate('invalidEmailFormat');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    _buildLabel(loc.translate('passwordLabel')),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _passwordController,
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: subTextColor,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return loc.translate('enterPassword');
                        }
                        if (value.length < 6) {
                          return loc.translate('passwordMinLength');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(
                          loc.translate('forgotPassword'),
                          style: GoogleFonts.inter(
                            color: primaryBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: scaffoldBg,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: authProv.isLoading ? null : () => _submit(loc),
                        child: authProv.isLoading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: scaffoldBg,
                                ),
                              )
                            : Text(
                                loc.translate('loginButton'),
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    Row(
                      children: [
                        Expanded(child: Divider(color: borderColor)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            loc.translate('or'),
                            style: GoogleFonts.inter(color: subTextColor, fontSize: 12),
                          ),
                        ),
                        Expanded(child: Divider(color: borderColor)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          loc.translate('noAccountYet'),
                          style: GoogleFonts.inter(color: subTextColor, fontSize: 14),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: Text(
                            loc.translate('createNewAccount'),
                            style: GoogleFonts.inter(
                              color: accentGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ],
    ),
    ),
  );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: textColor,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: textColor, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: subTextColor.withOpacity(0.6)),
        filled: true,
        fillColor: cardBg,
        prefixIcon: Icon(icon, color: subTextColor, size: 20),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}