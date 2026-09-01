import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/activity_log_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

/// Manager/Admin-only audit trail. Reads real entries from Firestore
/// (`activityLogs`) that get written whenever the app performs a
/// significant admin action (creating a subscription, changing a user's
/// role). Empty until such actions happen — never shows fabricated data.
class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ActivityLogProvider>(context, listen: false).fetchLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final logProv = Provider.of<ActivityLogProvider>(context);
    final loc = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final dateFmt = DateFormat('yyyy-MM-dd  hh:mm a');

    if (!authProv.isManager) {
      return Container(
        color: colors.scaffoldBg,
        child: Center(
          child: Text(loc.translate('genericError'), style: TextStyle(color: colors.subTextColor)),
        ),
      );
    }

    return Container(
      color: colors.scaffoldBg,
      child: RefreshIndicator(
        onRefresh: () => logProv.fetchLogs(),
        child: logProv.isLoading && logProv.logs.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : logProv.logs.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Icon(Icons.history_outlined, size: 48, color: colors.subTextColor),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(loc.translate('noActivity'),
                            style: TextStyle(color: colors.subTextColor, fontSize: 15)),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: logProv.logs.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10),
                    itemBuilder: (ctx, index) {
                      final log = logProv.logs[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.borderColor),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: colors.primaryBlue.withOpacity(0.12),
                              child: Icon(Icons.bolt, color: colors.primaryBlue, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(log.action,
                                            style: TextStyle(color: colors.textColor, fontWeight: FontWeight.bold)),
                                      ),
                                      Text(dateFmt.format(log.timestamp),
                                          style: TextStyle(color: colors.subTextColor, fontSize: 11)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(log.details, style: TextStyle(color: colors.subTextColor, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text('${loc.translate('performedByLabel')}: ${log.userName}',
                                      style: TextStyle(color: colors.subTextColor, fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
