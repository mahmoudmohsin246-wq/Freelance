import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/financial_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/activity_log_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

/// Manager/Admin-only screen for searching a user by email and creating a
/// subscription for them (duration + manually entered amount paid). Expiry
/// is calculated automatically and the subscription is linked by Firebase
/// UID. Normal users never see this screen — see [MySubscriptionScreen].
class ManagerSubscriptionsScreen extends StatefulWidget {
  const ManagerSubscriptionsScreen({super.key});

  @override
  State<ManagerSubscriptionsScreen> createState() => _ManagerSubscriptionsScreenState();
}

class _ManagerSubscriptionsScreenState extends State<ManagerSubscriptionsScreen> {
  final _emailController = TextEditingController();
  final _amountController = TextEditingController();

  // durationMonths -> label key
  final List<_DurationOption> _durations = const [
    _DurationOption(months: 1, key: 'duration1Month'),
    _DurationOption(months: 3, key: 'duration3Months'),
    _DurationOption(months: 6, key: 'duration6Months'),
    _DurationOption(months: 12, key: 'duration1Year'),
  ];
  int _selectedMonths = 1;

  bool _searched = false;
  bool _submitting = false;
  bool _promotingRole = false;

  @override
  void dispose() {
    _emailController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  DateTime get _expiryPreview {
    final now = DateTime.now();
    return DateTime(now.year, now.month + _selectedMonths, now.day);
  }

  Future<void> _search(SubscriptionProvider subProv) async {
    FocusScope.of(context).unfocus();
    setState(() => _searched = true);
    final user = await subProv.searchUserByEmail(_emailController.text);
    if (user != null && mounted) {
      await subProv.fetchUserSubscriptions(user.id);
    }
  }

  Future<void> _createSubscription(
    BuildContext context,
    SubscriptionProvider subProv,
    AppLocalizations loc,
  ) async {
    final user = subProv.searchedUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('pleaseSearchUserFirst')), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('pleaseEnterValidAmount')), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final durationOption = _durations.firstWhere((d) => d.months == _selectedMonths);

    setState(() => _submitting = true);
    final financialProvider = Provider.of<FinancialProvider>(context, listen: false);
    final activityLogProvider = Provider.of<ActivityLogProvider>(context, listen: false);
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    // Share the same 6-digit code between the user's account and this
    // subscription, so their code stays stable across renewals.
    final code = await authProv.ensureAttendanceCode(user);
    final ok = await subProv.addManagerSubscription(
      userId: user.id,
      userEmail: user.email,
      userName: user.name,
      durationMonths: _selectedMonths,
      durationLabel: loc.translate(durationOption.key),
      amountPaid: amount,
      attendanceCode: code,
      financialProvider: financialProvider,
      activityLogProvider: activityLogProvider,
      actingManager: authProv.currentUser,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.translate(ok
            ? (subProv.lastActionWasRenewal ? 'subscriptionRenewedSuccess' : 'subscriptionCreatedSuccess')
            : 'subscriptionCreationFailed')),
        backgroundColor: ok ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (ok) {
      _amountController.clear();
      await subProv.fetchUserSubscriptions(user.id);
    }
  }

  Future<void> _toggleEmployeeRole(
    BuildContext context,
    SubscriptionProvider subProv,
    AppLocalizations loc,
  ) async {
    final user = subProv.searchedUser;
    if (user == null) return;
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final newRole = user.role == UserRole.employee ? UserRole.coach : UserRole.employee;

    setState(() => _promotingRole = true);
    final ok = await authProv.updateUserRole(userId: user.id, newRole: newRole);
    if (!mounted) return;
    if (ok) {
      final activityLogProvider = Provider.of<ActivityLogProvider>(context, listen: false);
      await activityLogProvider.logAction(
        action: newRole == UserRole.employee ? 'User promoted to Employee' : 'User reverted to normal user',
        entityType: 'user',
        details: '${user.name} (${user.email})',
        userId: authProv.currentUser?.id ?? '',
        userName: authProv.currentUser?.name ?? 'Manager',
      );
      if (!mounted) return;
    }
    setState(() => _promotingRole = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.translate(ok ? 'roleUpdatedSuccess' : 'roleUpdateFailed')),
        backgroundColor: ok ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (ok) {
      await subProv.searchUserByEmail(user.email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final subProv = Provider.of<SubscriptionProvider>(context);

    // Defense in depth: this screen is only routed to for managers, but
    // guard here too in case of navigation misuse.
    if (!authProv.isManager) {
      return Center(
        child: Text(loc.translate('genericError'), style: TextStyle(color: colors.textColor)),
      );
    }

    final user = subProv.searchedUser;
    final dateFmt = DateFormat('yyyy-MM-dd');

    return Container(
      color: colors.scaffoldBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(loc.translate('manageSubscriptionsTitle'),
                    style: TextStyle(color: colors.textColor, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(loc.translate('manageSubscriptionsDesc'),
                    style: TextStyle(color: colors.subTextColor, fontSize: 13)),
                const SizedBox(height: 20),

                // Search
                Text(loc.translate('searchUserByEmailLabel'),
                    style: TextStyle(color: colors.textColor, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: colors.textColor),
                        onSubmitted: (_) => _search(subProv),
                        decoration: InputDecoration(
                          hintText: loc.translate('searchUserByEmailHint'),
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
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primaryBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: subProv.isLoading ? null : () => _search(subProv),
                        child: subProv.isLoading
                            ? const SizedBox(
                                width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(loc.translate('searchButton')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_searched && !subProv.isLoading && user == null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(loc.translate('userNotFoundMsg'), style: const TextStyle(color: Colors.redAccent)),
                  ),

                if (user != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.translate('selectedUserLabel'),
                            style: TextStyle(color: colors.subTextColor, fontSize: 11)),
                        const SizedBox(height: 6),
                        Row(
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
                                  Text(user.name, style: TextStyle(color: colors.textColor, fontWeight: FontWeight.bold)),
                                  Text(user.email, style: TextStyle(color: colors.subTextColor, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Role management: promote a normal user to Employee, or revert.
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.borderColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc.translate('currentRoleLabel'),
                                  style: TextStyle(color: colors.subTextColor, fontSize: 11)),
                              const SizedBox(height: 4),
                              Text(
                                loc.translate(user.role == UserRole.admin
                                    ? 'roleManager'
                                    : user.role == UserRole.employee
                                        ? 'roleEmployee'
                                        : 'roleCoach'),
                                style: TextStyle(color: colors.textColor, fontWeight: FontWeight.bold),
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
                            onPressed: _promotingRole ? null : () => _toggleEmployeeRole(context, subProv, loc),
                            child: _promotingRole
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: colors.primaryBlue))
                                : Text(
                                    loc.translate(user.role == UserRole.employee
                                        ? 'revertToUserButton'
                                        : 'promoteToEmployeeButton'),
                                    style: TextStyle(color: colors.primaryBlue),
                                  ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(loc.translate('subscriptionDurationLabel'),
                      style: TextStyle(color: colors.textColor, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: colors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedMonths,
                        isExpanded: true,
                        dropdownColor: colors.cardBg,
                        style: TextStyle(color: colors.textColor),
                        items: _durations
                            .map((d) => DropdownMenuItem<int>(
                                  value: d.months,
                                  child: Text(loc.translate(d.key)),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedMonths = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Text(loc.translate('amountPaidLabel'),
                      style: TextStyle(color: colors.textColor, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: colors.textColor),
                    decoration: InputDecoration(
                      hintText: loc.translate('amountPaidHint'),
                      filled: true,
                      fillColor: colors.cardBg,
                      prefixIcon: const Icon(Icons.payments_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.borderColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: colors.primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(loc.translate('expiryDatePreviewLabel'),
                            style: TextStyle(color: colors.textColor, fontWeight: FontWeight.w600)),
                        Text(dateFmt.format(_expiryPreview),
                            style: TextStyle(color: colors.primaryBlue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _submitting ? null : () => _createSubscription(context, subProv, loc),
                      child: _submitting
                          ? const SizedBox(
                              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(loc.translate('createSubscriptionButton'),
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 28),

                  Text(loc.translate('subscriptionHistoryTitle'),
                      style: TextStyle(color: colors.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (subProv.userSubscriptionHistory.isEmpty)
                    Text(loc.translate('noSubscriptionHistory'), style: TextStyle(color: colors.subTextColor))
                  else
                    ...subProv.userSubscriptionHistory.map((s) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.borderColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (s.isCurrentlyActive ? Colors.green : Colors.redAccent).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  loc.translate(s.isCurrentlyActive ? 'statusActive' : 'statusExpired'),
                                  style: TextStyle(
                                    color: s.isCurrentlyActive ? Colors.green : Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.durationLabel,
                                        style: TextStyle(color: colors.textColor, fontWeight: FontWeight.bold)),
                                    Text(
                                      '${loc.translate('startDateLabel')}: ${dateFmt.format(s.startDate)}  •  '
                                      '${loc.translate('expiryDateLabel')}: ${dateFmt.format(s.expiryDate)}',
                                      style: TextStyle(color: colors.subTextColor, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Text('${s.amountPaid.toStringAsFixed(0)}',
                                  style: TextStyle(color: colors.textColor, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DurationOption {
  final int months;
  final String key;
  const _DurationOption({required this.months, required this.key});
}
