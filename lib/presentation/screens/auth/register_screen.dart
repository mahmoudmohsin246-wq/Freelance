import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _academyNameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  XFile? _pickedAvatar;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _roleChoice = 'coach'; // 'manager' | 'employee' | 'coach'
  bool _obscureManagerCode = true;
  final _managerCodeController = TextEditingController();

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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _academyNameController.dispose();
    _nationalIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _managerCodeController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: primaryBlue),
              title: Text('المعرض', style: TextStyle(color: textColor)),
              onTap: () async {
                Navigator.pop(context);
                final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                if (image != null) setState(() => _pickedAvatar = image);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: primaryBlue),
              title: Text('الكاميرا', style: TextStyle(color: textColor)),
              onTap: () async {
                Navigator.pop(context);
                final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                if (image != null) setState(() => _pickedAvatar = image);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(AppLocalizations loc) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final authProv = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProv.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      phone: _phoneController.text.trim(),
      academyName: _academyNameController.text.trim(),
      nationalId: _nationalIdController.text.trim(),
      avatarFile: _pickedAvatar,
      roleChoice: _roleChoice,
      managerCode: _managerCodeController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.translate('verificationEmailSent'), style: GoogleFonts.inter()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    if (authProv.errorMessage != null) {
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
    _colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryBlue, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
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
                    // اختيار صورة البروفايل
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: _pickAvatar,
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: cardBg,
                              backgroundImage: _pickedAvatar != null
                                  ? (kIsWeb
                                      ? NetworkImage(_pickedAvatar!.path)
                                      : FileImage(File(_pickedAvatar!.path)) as ImageProvider)
                                  : null,
                              child: _pickedAvatar == null
                                  ? Icon(Icons.person_rounded, size: 48, color: subTextColor)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _pickAvatar,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      loc.translate('createNewAccount'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.translate('registerSubtitle'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: subTextColor, fontSize: 14),
                    ),
                    const SizedBox(height: 28),

                    // الاسم الكامل
                    _buildLabel(loc.translate('fullName')),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _nameController,
                      hint: loc.translate('enterFullName'),
                      icon: Icons.person_outline_rounded,
                      keyboardType: TextInputType.name,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return loc.translate('enterName');
                        }
                        if (value.trim().length < 3) {
                          return loc.translate('nameTooShort');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // اسم الأكاديمية
                    _buildLabel("اسم الأكاديمية"),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _academyNameController,
                      hint: "أدخل اسم الأكاديمية",
                      icon: Icons.sports_soccer_outlined,
                      keyboardType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "يرجى إدخال اسم الأكاديمية";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // رقم الهاتف
                    _buildLabel("رقم الهاتف"),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _phoneController,
                      hint: "01xxxxxxxxx",
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "يرجى إدخال رقم الهاتف";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // الرقم القومي
                    _buildLabel(loc.translate('nationalIdLabel')),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _nationalIdController,
                      hint: loc.translate('nationalIdHint'),
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return loc.translate('nationalIdInvalid');
                        }
                        if (value.trim().length != 14) {
                          return loc.translate('nationalIdInvalid');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // البريد الإلكتروني
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
                    const SizedBox(height: 18),

                    // كلمة السر
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
                    const SizedBox(height: 18),

                    // تأكيد كلمة السر
                    _buildLabel(loc.translate('confirmPassword')),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: subTextColor,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return loc.translate('confirmPasswordRequired');
                        }
                        if (value != _passwordController.text) {
                          return loc.translate('passwordsMismatch');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // نوع الحساب
                    _buildLabel(loc.translate('accountType')),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          _roleOption('coach', loc.translate('roleCoach'), loc.translate('roleCoachDesc'),
                              Icons.person_outline_rounded),
                          Divider(height: 1, color: borderColor),
                          _roleOption('manager', loc.translate('roleManager'), loc.translate('roleManagerDesc'),
                              Icons.admin_panel_settings_outlined),
                        ],
                      ),
                    ),

                    if (_roleChoice == 'manager') ...[
                      const SizedBox(height: 14),
                      _buildLabel(loc.translate('managerAccessCode')),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _managerCodeController,
                        hint: loc.translate('managerAccessCodeHint'),
                        icon: Icons.verified_user_outlined,
                        obscureText: _obscureManagerCode,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureManagerCode
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: subTextColor,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() => _obscureManagerCode = !_obscureManagerCode);
                          },
                        ),
                        validator: (value) {
                          if (_roleChoice != 'manager') return null;
                          if (value == null || value.trim().isEmpty) {
                            return loc.translate('managerCodeRequired');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        loc.translate('managerRoleHint'),
                        style: GoogleFonts.inter(color: subTextColor, fontSize: 11),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // زر إنشاء الحساب
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentGreen,
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
                                loc.translate('createAccountButton'),
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          loc.translate('alreadyHaveAccount'),
                          style: GoogleFonts.inter(color: subTextColor, fontSize: 14),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            loc.translate('loginButton'),
                            style: GoogleFonts.inter(
                              color: primaryBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleOption(String value, String title, String desc, IconData icon) {
    final isSelected = _roleChoice == value;
    return InkWell(
      onTap: () => setState(() => _roleChoice = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _roleChoice,
              activeColor: primaryBlue,
              onChanged: (v) => setState(() => _roleChoice = v ?? 'coach'),
            ),
            Icon(icon, color: isSelected ? primaryBlue : subTextColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                        color: isSelected ? primaryBlue : textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      )),
                  Text(desc, style: GoogleFonts.inter(color: subTextColor, fontSize: 11)),
                ],
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