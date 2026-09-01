import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/invitations_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

class InvitationsScreenImpl extends StatelessWidget {
  const InvitationsScreenImpl({super.key});

  String _roleLabel(String role, AppLocalizations loc) {
    switch (role) {
      case 'employee':
        return loc.translate('roleEmployee');
      case 'coach':
        return loc.translate('roleCoach');
      default:
        return role;
    }
  }

  void _showSendInvitationDialog(BuildContext context, AppLocalizations loc, AppColors colors) {
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedRole = 'coach';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: colors.cardBg,
          title: Text(loc.translate('sendInvitationTitle'), style: TextStyle(color: colors.textColor)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(color: colors.textColor),
                  decoration: InputDecoration(
                    labelText: loc.translate('emailLabel'),
                    hintText: loc.translate('invitationEmailHint'),
                    labelStyle: TextStyle(color: colors.subTextColor),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return loc.translate('enterEmail');
                    if (!v.contains('@') || !v.contains('.')) return loc.translate('invalidEmailFormat');
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(loc.translate('inviteeRoleLabel'),
                      style: TextStyle(color: colors.subTextColor, fontSize: 12)),
                ),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  value: 'coach',
                  groupValue: selectedRole,
                  activeColor: colors.primaryBlue,
                  title: Text(loc.translate('roleCoach'), style: TextStyle(color: colors.textColor)),
                  onChanged: (v) => setDialogState(() => selectedRole = v ?? 'coach'),
                ),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  value: 'employee',
                  groupValue: selectedRole,
                  activeColor: colors.primaryBlue,
                  title: Text(loc.translate('roleEmployee'), style: TextStyle(color: colors.textColor)),
                  onChanged: (v) => setDialogState(() => selectedRole = v ?? 'coach'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc.translate('cancel'), style: TextStyle(color: colors.subTextColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colors.primaryBlue),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Provider.of<InvitationsProvider>(context, listen: false)
                      .sendInvitation(emailCtrl.text.trim(), selectedRole);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.translate('invitationSentSuccess')),
                      backgroundColor: colors.accentGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text(loc.translate('inviteUser'), style: TextStyle(color: colors.onPrimary)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invitationsProv = context.watch<InvitationsProvider>();
    final isManager = context.watch<AuthProvider>().isManager;
    final loc = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    return Container(
      color: colors.scaffoldBg,
      child: Column(
        children: [
          if (isManager)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryBlue,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showSendInvitationDialog(context, loc, colors),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: Text(loc.translate('inviteUser'), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colors.subTextColor, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(loc.translate('invitationsManagersOnlyHint'),
                        style: TextStyle(color: colors.subTextColor, fontSize: 12)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: invitationsProv.isLoading
                ? Center(child: CircularProgressIndicator(color: colors.primaryBlue))
                : invitationsProv.invitations.isEmpty
                    ? Center(
                        child: Text(loc.translate('noPendingInvitations'),
                            style: TextStyle(color: colors.subTextColor, fontSize: 16)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: invitationsProv.invitations.length,
                        itemBuilder: (ctx, index) {
                          final invite = invitationsProv.invitations[index];
                          final dateStr =
                              '${invite.createdAt.year}/${invite.createdAt.month.toString().padLeft(2, '0')}/${invite.createdAt.day.toString().padLeft(2, '0')}';
                          return Card(
                            color: colors.cardBg,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: colors.primaryBlue.withOpacity(0.13),
                                child: Icon(Icons.mail_outline, color: colors.primaryBlue),
                              ),
                              title: Text(invite.email,
                                  style: TextStyle(color: colors.textColor, fontWeight: FontWeight.bold),
                                  textDirection: TextDirection.ltr),
                              subtitle: Text(
                                '${_roleLabel(invite.role, loc)} • ${loc.translate('sentOnLabel')} $dateStr',
                                style: TextStyle(color: colors.subTextColor, fontSize: 12),
                              ),
                              trailing: isManager
                                  ? IconButton(
                                      icon: const Icon(Icons.close, color: Colors.redAccent),
                                      onPressed: () => invitationsProv.cancelInvitation(invite.id),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
