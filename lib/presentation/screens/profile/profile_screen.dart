import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late AppColors _colors;
  Color get scaffoldBg => _colors.scaffoldBg;
  Color get cardBg => _colors.cardBg;
  Color get primaryBlue => _colors.primaryBlue;
  Color get accentGreen => _colors.accentGreen;
  Color get textColor => _colors.textColor;
  Color get subTextColor => _colors.subTextColor;
  Color get borderColor => _colors.borderColor;
  Color get goldColor => _colors.gold;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _academyController;
  late TextEditingController _nationalIdController;
  final String _selectedSportKey = 'sportFootball';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _academyController = TextEditingController(text: user?.academyName ?? '');
    _nationalIdController = TextEditingController(text: user?.nationalId ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _academyController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  Future<void> _save(AppLocalizations loc) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final authProv = Provider.of<AuthProvider>(context, listen: false);
    await authProv.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      academyName: _academyController.text.trim(),
      sport: 'sportFootball',
      nationalId: _nationalIdController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.translate('profileSavedSuccess')),
        backgroundColor: accentGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showImageSourceDialog(AppLocalizations loc) {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: primaryBlue),
              title: Text(loc.translate('gallery') ?? 'المعرض', style: TextStyle(color: textColor)),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await authProv.uploadAvatar(ImageSource.gallery);
                if (!mounted) return;
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.translate('profileSavedSuccess')),
                      backgroundColor: accentGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else if (authProv.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.translate(authProv.errorMessage!)),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: primaryBlue),
              title: Text(loc.translate('camera') ?? 'الكاميرا', style: TextStyle(color: textColor)),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await authProv.uploadAvatar(ImageSource.camera);
                if (!mounted) return;
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.translate('profileSavedSuccess')),
                      backgroundColor: accentGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else if (authProv.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.translate(authProv.errorMessage!)),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMyQrCode(BuildContext context, UserModel user, AppLocalizations loc) {
    // IMPORTANT: the scanner matches members by their subscription id, and
    // employees by their own account id — these are two different id
    // spaces. Showing the wrong one means the QR (and any manual entry)
    // can never match anything when scanned/typed.
    final subProv = Provider.of<SubscriptionProvider>(context, listen: false);
    String? matchId;
    String? unavailableReason;
    if (user.role == UserRole.employee || user.role == UserRole.admin) {
      matchId = user.id;
    } else {
      final activeSub = subProv.userActiveSubscription;
      if (activeSub != null) {
        matchId = activeSub.id;
      } else {
        unavailableReason = loc.translate('noActiveSubscriptionMsg');
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        title: Text(loc.translate('myQrCode'), style: TextStyle(color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(user.name, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(loc.translate('myQrCodeHint'), style: TextStyle(color: subTextColor, fontSize: 12)),
            const SizedBox(height: 16),
            if (matchId == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  unavailableReason ?? loc.translate('genericError'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: QrImageView(data: matchId, version: QrVersions.auto, size: 200),
              ),
              const SizedBox(height: 14),
              // Plain-text fallback: staff can read/type this manually into
              // the scanner's "manual code" field if the camera or QR scan
              // isn't working — attendance no longer has to go through the
              // camera only.
              Text(loc.translate('manualCodeEntry'), style: TextStyle(color: subTextColor, fontSize: 11)),
              const SizedBox(height: 6),
              SelectableText(
                matchId,
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ],
        ),
        actions: [
          if (matchId != null)
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: matchId!));
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(loc.translate('copiedToClipboard')), behavior: SnackBarBehavior.floating),
                );
              },
              icon: Icon(Icons.copy_rounded, size: 16, color: primaryBlue),
              label: Text(loc.translate('copyCode'), style: TextStyle(color: primaryBlue)),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.translate('close'), style: TextStyle(color: primaryBlue)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordSheet(AppLocalizations loc) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(loc.translate('changePassword'),
                        style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _sheetField(oldCtrl, loc.translate('oldPassword'), loc),
                    const SizedBox(height: 12),
                    _sheetField(newCtrl, loc.translate('newPassword'), loc, validateLength: true),
                    const SizedBox(height: 12),
                    _sheetField(confirmCtrl, loc.translate('confirmPassword'), loc, confirmOf: newCtrl),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: scaffoldBg,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: submitting
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setSheetState(() => submitting = true);
                                final authProv = Provider.of<AuthProvider>(context, listen: false);
                                final ok = await authProv.changePassword(oldCtrl.text, newCtrl.text);
                                setSheetState(() => submitting = false);
                                if (!ctx.mounted) return;
                                if (ok) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(loc.translate('passwordChangedSuccess')),
                                      backgroundColor: accentGreen,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(loc.translate(authProv.errorMessage ?? 'genericError')),
                                      backgroundColor: Colors.redAccent,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                        child: submitting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.2, color: scaffoldBg),
                              )
                            : Text(loc.translate('confirmChange'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetField(TextEditingController controller, String hint, AppLocalizations loc,
      {bool validateLength = false, TextEditingController? confirmOf}) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      style: TextStyle(color: textColor),
      validator: (value) {
        if (value == null || value.isEmpty) return loc.translate('requiredField');
        if (validateLength && value.length < 6) return loc.translate('minSixChars');
        if (confirmOf != null && value != confirmOf.text) return loc.translate('passwordsMismatch');
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: subTextColor),
        filled: true,
        fillColor: scaffoldBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context);
    final user = authProv.currentUser;
    final loc = AppLocalizations.of(context);
    _colors = AppColors.of(context);
    final themeProv = Provider.of<ThemeProvider>(context);

    if (user == null) {
      return Center(child: Text(loc.translate('notLoggedIn'), style: TextStyle(color: textColor)));
    }

    return Container(
      color: scaffoldBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: cardBg,
                      backgroundImage: user.avatarPath.isNotEmpty
                          ? NetworkImage(user.avatarPath)
                          : null,
                      child: authProv.isUploadingAvatar
                          ? SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: primaryBlue),
                            )
                          : (user.avatarPath.isEmpty
                              ? Icon(Icons.person, size: 46, color: subTextColor)
                              : null),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: authProv.isUploadingAvatar ? null : () => _showImageSourceDialog(loc),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
                          child: Icon(Icons.camera_alt, size: 16, color: scaffoldBg),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              _label(loc.translate('fullName')),
              const SizedBox(height: 8),
              _field(
                controller: _nameController,
                icon: Icons.person_outline_rounded,
                validator: (v) => (v == null || v.trim().isEmpty) ? loc.translate('nameRequired') : null,
              ),
              const SizedBox(height: 18),

              _label(loc.translate('phoneNumber')),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🇪🇬', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_drop_down, color: Color(0xFF94A3B8), size: 18),
                          SizedBox(width: 4),
                          Text('+20', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 24, color: borderColor),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        style: TextStyle(color: textColor, fontSize: 14),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return loc.translate('phoneRequired');
                          if (v.trim().length < 10) return loc.translate('phoneIncomplete');
                          return null;
                        },
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              _label(loc.translate('academyName')),
              const SizedBox(height: 8),
              _field(
                controller: _academyController,
                icon: Icons.shield_outlined,
                validator: (v) => (v == null || v.trim().isEmpty) ? loc.translate('academyNameRequired') : null,
              ),
              const SizedBox(height: 18),

              _label(loc.translate('academyType')),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, color: subTextColor, size: 18),
                    const Spacer(),
                    Text('كرة القدم (Football)',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    const Icon(Icons.sports_soccer, color: Colors.green, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _label(loc.translate('nationalIdLabel')),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nationalIdController,
                keyboardType: TextInputType.number,
                maxLength: 14,
                style: TextStyle(color: textColor, fontSize: 14),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (v.trim().length != 14) return loc.translate('nationalIdInvalid');
                  return null;
                },
                decoration: InputDecoration(
                  counterText: '',
                  hintText: loc.translate('nationalIdHint'),
                  suffixIcon: Icon(Icons.badge_outlined, color: subTextColor, size: 20),
                  filled: true,
                  fillColor: cardBg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showChangePasswordSheet(loc),
                  icon: Icon(Icons.lock_reset_rounded, color: goldColor, size: 18),
                  label: Text(loc.translate('changePassword'),
                      style: TextStyle(color: goldColor, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 6),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showMyQrCode(context, user, loc),
                  icon: Icon(Icons.qr_code_rounded, color: primaryBlue, size: 18),
                  label: Text(loc.translate('myQrCode'),
                      style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: themeProv.isDarkMode,
                  activeColor: primaryBlue,
                  onChanged: (_) => themeProv.toggleTheme(),
                  secondary: Icon(
                    themeProv.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                    color: primaryBlue,
                  ),
                  title: Text(loc.translate('lightDarkMode'),
                      style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    themeProv.isDarkMode ? loc.translate('darkModeLabel') : loc.translate('lightModeLabel'),
                    style: TextStyle(color: subTextColor, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: scaffoldBg,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saving ? null : () => _save(loc),
                  child: _saving
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: scaffoldBg),
                        )
                      : Text(loc.translate('saveChanges'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Align(
        alignment: Alignment.centerRight,
        child: Text(text, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
      );

  Widget _field({
    required TextEditingController controller,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: textColor, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        suffixIcon: Icon(icon, color: subTextColor, size: 20),
        filled: true,
        fillColor: cardBg,
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
      ),
    );
  }
}
