import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

void _promptSwitchAccount(
  BuildContext context,
  AuthProvider authProv,
  UserModel acc,
  AppLocalizations loc,
  Color cardBg,
  Color textColor,
  Color subTextColor,
  Color primaryBlue,
  Color accentGreen,
) {
  final passwordCtrl = TextEditingController();
  bool submitting = false;
  String? error;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: cardBg,
        title: Text('${loc.translate('switchWorkspace')}: ${acc.name}',
            style: TextStyle(color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(acc.email, style: TextStyle(color: subTextColor, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: loc.translate('passwordLabel'),
                labelStyle: TextStyle(color: subTextColor),
                errorText: error,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: submitting ? null : () => Navigator.pop(ctx),
            child: Text(loc.translate('cancel'), style: TextStyle(color: textColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            onPressed: submitting
                ? null
                : () async {
                    if (passwordCtrl.text.isEmpty) {
                      setDialogState(() => error = loc.translate('enterPassword'));
                      return;
                    }
                    setDialogState(() {
                      submitting = true;
                      error = null;
                    });
                    final ok = await authProv.switchAccount(acc.email, passwordCtrl.text);
                    if (!ctx.mounted) return;
                    if (ok) {
                      Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${loc.translate('switchedTo')} ${acc.name}'),
                            backgroundColor: accentGreen,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } else {
                      setDialogState(() {
                        submitting = false;
                        error = loc.translate(authProv.errorMessage ?? 'genericError');
                      });
                    }
                  },
            child: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(loc.translate('switchWorkspace')),
          ),
        ],
      ),
    ),
  );
}

class WorkspaceSwitcherScreen extends StatelessWidget {
  const WorkspaceSwitcherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final user = authProv.currentUser;
    final others = authProv.otherAccounts;
    final loc = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final scaffoldBg = colors.scaffoldBg;
    final cardBg = colors.cardBg;
    final primaryBlue = colors.primaryBlue;
    final accentGreen = colors.accentGreen;
    final textColor = colors.textColor;
    final subTextColor = colors.subTextColor;
    final avatarColors = <Color>[
      accentGreen,
      primaryBlue,
      const Color(0xFFF59E0B),
      const Color(0xFFA855F7),
      const Color(0xFFEC4899),
    ];

    if (user == null) {
      return Center(child: Text(loc.translate('notLoggedIn'), style: TextStyle(color: textColor)));
    }

    return Container(
      color: scaffoldBg,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: primaryBlue.withOpacity(0.15),
                  child: Icon(Icons.person, color: primaryBlue, size: 34),
                ),
                const SizedBox(height: 14),
                Text(
                  user.name,
                  style: TextStyle(
                      color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  user.academyName.isNotEmpty ? user.academyName : loc.translate('noAcademyNameYet'),
                  style: TextStyle(color: primaryBlue, fontSize: 15),
                ),
                if (user.sport.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${loc.translate('academyType')}: ${loc.translate(user.sport)}',
                    style: TextStyle(color: subTextColor, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  loc.translate('chooseWorkspace'),
                  style: TextStyle(color: subTextColor.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (others.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  loc.translate('noOtherAccountsOnDevice'),
                  style: TextStyle(color: subTextColor, fontSize: 13),
                ),
              ),
            )
          else
            ...List.generate(others.length, (i) {
              final acc = others[i];
              final color = avatarColors[i % avatarColors.length];
              final initial = acc.academyName.isNotEmpty
                  ? acc.academyName[0].toUpperCase()
                  : acc.name.isNotEmpty
                      ? acc.name[0].toUpperCase()
                      : '?';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _promptSwitchAccount(context, authProv, acc, loc, cardBg,
                        textColor, subTextColor, primaryBlue, accentGreen),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: color,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  acc.academyName.isNotEmpty ? acc.academyName : acc.name,
                                  style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  acc.role == UserRole.admin
                                      ? loc.translate('projectManager')
                                      : loc.translate('member'),
                                  style: TextStyle(color: subTextColor, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_left_rounded, color: subTextColor),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}