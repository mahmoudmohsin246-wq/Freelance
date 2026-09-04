import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../attendance/person_attendance_screen.dart';
import 'staff_attendance_scanner_screen.dart';

class EmployeeAttendanceScreenImpl extends StatefulWidget {
  const EmployeeAttendanceScreenImpl({super.key});

  @override
  State<EmployeeAttendanceScreenImpl> createState() => _EmployeeAttendanceScreenImplState();
}

class _EmployeeAttendanceScreenImplState extends State<EmployeeAttendanceScreenImpl> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final academyName = Provider.of<AuthProvider>(context, listen: false).currentUser?.academyName ?? '';
      Provider.of<AttendanceProvider>(context, listen: false).loadAcademyAttendance(academyName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final attendanceProv = context.watch<AttendanceProvider>();
    final subProv = context.watch<SubscriptionProvider>();
    final loc = AppLocalizations.of(context);
    // A "coach" role account that also has a subscription linked to it is
    // actually a player/trainee (no dedicated player role exists yet — see
    // registration flow), not real staff, so it's excluded here.
    final subscriberIds = subProv.subscriptions.map((s) => s.userId).where((id) => id.isNotEmpty).toSet();
    final employees =
        authProv.employeeAccounts.where((e) => !subscriberIds.contains(e.id)).toList();
    final colors = AppColors.of(context);
    final scaffoldBg = colors.scaffoldBg;
    final cardBg = colors.cardBg;
    final primaryBlue = colors.primaryBlue;
    final accentGreen = colors.accentGreen;
    final textColor = colors.textColor;
    final subTextColor = colors.subTextColor;

    return Container(
      color: scaffoldBg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: scaffoldBg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StaffAttendanceScannerScreen()),
                  );
                },
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: Text(loc.translate('scanEmployeeAttendance'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          Expanded(
            child: employees.isEmpty
                ? Center(
                    child: Text(loc.translate('noEmployeesRegisteredYet'),
                        style: TextStyle(color: subTextColor, fontSize: 15)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: employees.length,
                    itemBuilder: (ctx, index) {
                      final emp = employees[index];
                      final checkedIn = attendanceProv.employeeCheckedInToday(emp.id);
                      return Card(
                        color: cardBg,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PersonAttendanceScreen(
                                  personId: emp.id,
                                  name: emp.name,
                                  email: emp.email,
                                  phone: emp.phone,
                                  nationalId: emp.nationalId,
                                  roleLabel: loc.translate(emp.role == UserRole.admin
                                      ? 'roleManager'
                                      : emp.role == UserRole.employee
                                          ? 'roleEmployee'
                                          : 'roleCoach'),
                                ),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: (checkedIn ? accentGreen : subTextColor).withOpacity(0.15),
                            child: Icon(
                              checkedIn ? Icons.check_circle : Icons.person_outline,
                              color: checkedIn ? accentGreen : subTextColor,
                            ),
                          ),
                          title: Text(emp.name,
                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            checkedIn ? loc.translate('checkedInToday') : loc.translate('notCheckedInToday'),
                            style: TextStyle(color: checkedIn ? accentGreen : subTextColor, fontSize: 12),
                          ),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${attendanceProv.employeeAttendanceCount(emp.id)}',
                                style: TextStyle(color: subTextColor, fontSize: 12),
                              ),
                              IconButton(
                                icon: Icon(Icons.qr_code, size: 20, color: subTextColor),
                                tooltip: loc.translate('showQrCode'),
                                onPressed: () => _showEmployeeCodeDialog(context, emp, loc, colors),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showEmployeeCodeDialog(
      BuildContext context, UserModel emp, AppLocalizations loc, AppColors colors) async {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final code = await authProv.ensureAttendanceCode(emp);
    final pubUserId = await authProv.ensurePublicUserId(emp);
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(loc.translate('playerQrCode'), style: TextStyle(color: colors.textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emp.name, style: TextStyle(color: colors.textColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: QrImageView(data: code, version: QrVersions.auto, size: 200),
            ),
            const SizedBox(height: 14),
            Text(
              code,
              style: TextStyle(
                color: colors.primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 26,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text('كود حضور الموظف (Attendance Code)', style: TextStyle(color: colors.subTextColor, fontSize: 11)),
            if (pubUserId.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'معرّف الموظف: $pubUserId',
                style: TextStyle(color: colors.textColor, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.translate('close'), style: TextStyle(color: colors.primaryBlue)),
          ),
        ],
      ),
    );
  }
}
