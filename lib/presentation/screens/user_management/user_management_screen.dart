import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/activity_log_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';






class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _busyUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).fetchAllUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleRole(AuthProvider authProv, UserModel user, AppLocalizations loc) async {
    final newRole = user.role == UserRole.employee ? UserRole.coach : UserRole.employee;
    setState(() => _busyUserId = user.id);
    final ok = await authProv.updateUserRole(userId: user.id, newRole: newRole);
    if (ok) {
      await authProv.fetchAllUsers();
      if (mounted) {
        final activityLogProvider = Provider.of<ActivityLogProvider>(context, listen: false);
        await activityLogProvider.logAction(
          action: newRole == UserRole.employee
              ? loc.translate('userPromotedToEmployeeAction')
              : loc.translate('userRevertedToNormalAction'),
          entityType: 'user',
          details: '${user.name} (${user.email})',
          userId: authProv.currentUser?.id ?? '',
          userName: authProv.currentUser?.name ?? 'Manager',
        );
      }
    }
    if (!mounted) return;
    setState(() => _busyUserId = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.translate(ok ? 'roleUpdatedSuccess' : 'roleUpdateFailed')),
        backgroundColor: ok ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context);
    final loc = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    if (!authProv.isManager) {
      return Container(
        color: colors.scaffoldBg,
        child: Center(
          child: Text(loc.translate('genericError'), style: TextStyle(color: colors.subTextColor)),
        ),
      );
    }

    final q = _query.trim().toLowerCase();
    final users = q.isEmpty
        ? authProv.allUsers
        : authProv.allUsers
            .where((u) =>
                u.name.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q) ||
                u.phone.toLowerCase().contains(q))
            .toList();

    return Container(
      color: colors.scaffoldBg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(color: colors.textColor),
              decoration: InputDecoration(
                hintText: loc.translate('searchUsersHint'),
                filled: true,
                fillColor: colors.cardBg,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.borderColor),
                ),
              ),
            ),
          ),
          Expanded(
            child: authProv.isLoadingAllUsers && authProv.allUsers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : users.isEmpty
                    ? Center(
                        child: Text(loc.translate('noUsersFound'),
                            style: TextStyle(color: colors.subTextColor)),
                      )
                    : RefreshIndicator(
                        onRefresh: () => authProv.fetchAllUsers(),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: users.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, index) {
                            final user = users[index];
                            final roleLabel = loc.translate(user.role == UserRole.admin
                                ? 'roleManager'
                                : user.role == UserRole.employee
                                    ? 'roleEmployee'
                                    : 'roleCoach');
                            final busy = _busyUserId == user.id;
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: colors.cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.borderColor),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: colors.primaryBlue.withOpacity(0.15),
                                    backgroundImage: user.avatarPath.isNotEmpty ? NetworkImage(user.avatarPath) : null,
                                    child: user.avatarPath.isEmpty
                                        ? Icon(Icons.person, color: colors.primaryBlue)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(user.name,
                                            style: TextStyle(color: colors.textColor, fontWeight: FontWeight.bold)),
                                        Text(user.email, style: TextStyle(color: colors.subTextColor, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: colors.primaryBlue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(roleLabel,
                                              style: TextStyle(
                                                  color: colors.primaryBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (user.role != UserRole.admin)
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: colors.primaryBlue),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: busy ? null : () => _toggleRole(authProv, user, loc),
                                      child: busy
                                          ? SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: colors.primaryBlue))
                                          : Text(
                                              loc.translate(user.role == UserRole.employee
                                                  ? 'revertToUserButton'
                                                  : 'promoteToEmployeeButton'),
                                              style: TextStyle(color: colors.primaryBlue, fontSize: 12),
                                            ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}