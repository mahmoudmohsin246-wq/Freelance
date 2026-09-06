import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations loc) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProv.sendPasswordResetEmail(_emailController.text.trim());

    if (!mounted) return;
    if (success) {
      setState(() => _emailSent = true);
    } else if (authProv.errorMessage != null) {
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
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: colors.scaffoldBg,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textColor),
        title: Text(
          loc.translate('forgotPassword'),
          style: GoogleFonts.inter(color: colors.textColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _emailSent ? _buildSuccessState(loc, colors) : _buildFormState(loc, colors, authProv),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormState(AppLocalizations loc, AppColors colors, AuthProvider authProv) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.lock_reset_rounded, color: colors.primaryBlue, size: 64),
          const SizedBox(height: 20),
          Text(
            loc.translate('resetPasswordTitle'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: colors.textColor, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            loc.translate('resetPasswordDesc'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: colors.subTextColor, fontSize: 14),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.inter(color: colors.textColor, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'example@email.com',
              hintStyle: GoogleFonts.inter(color: colors.subTextColor.withOpacity(0.6)),
              filled: true,
              fillColor: colors.cardBg,
              prefixIcon: Icon(Icons.email_outlined, color: colors.subTextColor, size: 20),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.primaryBlue, width: 1.5),
              ),
            ),
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
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryBlue,
                foregroundColor: colors.scaffoldBg,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: authProv.isLoading ? null : () => _submit(loc),
              child: authProv.isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: colors.scaffoldBg),
                    )
                  : Text(
                      loc.translate('sendResetLink'),
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(AppLocalizations loc, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.mark_email_read_rounded, color: colors.accentGreen, size: 64),
        const SizedBox(height: 20),
        Text(
          loc.translate('resetLinkSentTitle'),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: colors.textColor, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          loc.translate('resetLinkSentDesc'),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: colors.subTextColor, fontSize: 14),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colors.primaryBlue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              loc.translate('backToLogin'),
              style: GoogleFonts.inter(color: colors.primaryBlue, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}