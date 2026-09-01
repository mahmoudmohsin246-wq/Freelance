import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/invitation_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../providers/auth_provider.dart';
import '../../common_widgets/empty_state_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final academyId = Provider.of<WorkspaceProvider>(context, listen: false).selectedAcademy?.id;
      if (academyId != null) {
        Provider.of<InvitationProvider>(context, listen: false).fetchInvitations(academyId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final invitationProvider = Provider.of<InvitationProvider>(context);
    final workspaceProvider = Provider.of<WorkspaceProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final loc = AppLocalizations.of(context);
    final academy = workspaceProvider.selectedAcademy;

    if (academy == null) {
      return const Center(child: Text('Please select an academy workspace.'));
    }

    bool isAdmin(AuthProvider auth) {
      final u = auth.currentUser;
      if (u == null) return false;
      final dyn = u as dynamic;
      try {
        final val = dyn.isAdmin;
        if (val is bool) return val;
      } catch (_) {}
      try {
        final role = dyn.role;
        if (role is String && role.toLowerCase() == 'admin') return true;
      } catch (_) {}
      try {
        final roles = dyn.roles;
        if (roles is Iterable && roles.contains('admin')) return true;
      } catch (_) {}
      return false;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('invitations'),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage staff & member invites for ${academy.name}',
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                  ],
                ),
                if (isAdmin(authProvider))
                  ElevatedButton.icon(
                    onPressed: () => _showInviteModal(context, academy.id, authProvider.currentUser?.name ?? 'Admin'),
                    icon: const Icon(Icons.send),
                    label: Text(loc.translate('inviteUser')),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: invitationProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : invitationProvider.invitations.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.mail_outline,
                          title: loc.translate('noPendingInvitations'),
                          description: 'There are no active or pending member invitations for this academy.',
                            actionLabel: isAdmin(authProvider) ? loc.translate('inviteUser') : null,
                            onAction: isAdmin(authProvider)
                              ? () => _showInviteModal(context, academy.id, authProvider.currentUser?.name ?? 'Admin')
                              : null,
                        )
                      : Card(
                          child: ListView.separated(
                            itemCount: invitationProvider.invitations.length,
                            separatorBuilder: (c, i) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final inv = invitationProvider.invitations[index];
                              return ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppColors.info,
                                  child: Icon(Icons.email, color: Colors.white, size: 20),
                                ),
                                title: Text(
                                  inv.email,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('Role: ${inv.role} • Invited by: ${inv.invitedBy}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        inv.status.name.toUpperCase(),
                                        style: const TextStyle(
                                          color: AppColors.warning,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isAdmin(authProvider)) ...[
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                                        onPressed: () => invitationProvider.cancelInvitation(inv.id),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteModal(BuildContext context, String academyId, String invitedBy) {
    final formKey = GlobalKey<FormState>();
    final emailCtrl = TextEditingController();
    final roleCtrl = TextEditingController(text: 'Trainer / Staff');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).translate('inviteUser'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)),
                  validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: roleCtrl,
                  decoration: const InputDecoration(labelText: 'Assigned Role', prefixIcon: Icon(Icons.badge)),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        await Provider.of<InvitationProvider>(context, listen: false).sendInvitation(
                          academyId: academyId,
                          email: emailCtrl.text,
                          role: roleCtrl.text,
                          invitedBy: invitedBy,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Send Invitation'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
