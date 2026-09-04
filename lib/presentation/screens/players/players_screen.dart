import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../providers/subscription_provider.dart';
import '../../providers/financial_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../attendance/person_attendance_screen.dart';
import 'attendance_scanner_screen.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _sortAscending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Subscription> _filteredAndSorted(List<Subscription> subs) {
    var list = subs.where((s) {
      if (_searchQuery.trim().isEmpty) return true;
      return s.playerName.toLowerCase().contains(_searchQuery.trim().toLowerCase());
    }).toList();

    list.sort((a, b) => _sortAscending
        ? a.playerName.compareTo(b.playerName)
        : b.playerName.compareTo(a.playerName));

    return list;
  }

  void _showPrintPreview(BuildContext context, List<Subscription> subs, AppLocalizations loc, AppColors colors) {
    final buffer = StringBuffer();
    for (var i = 0; i < subs.length; i++) {
      final s = subs[i];
      buffer.writeln('${i + 1}. ${s.playerName} — ${s.sportName} — ${s.price} ${loc.translate('currency')}');
    }
    final text = buffer.toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.cardBg,
        title: Text(loc.translate('printPreviewTitle'), style: TextStyle(color: colors.textColor)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: Text(text, style: TextStyle(color: colors.textColor))),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.translate('textCopied')), behavior: SnackBarBehavior.floating),
              );
            },
            child: Text(loc.translate('copyText'), style: TextStyle(color: colors.primaryBlue)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.translate('close'), style: TextStyle(color: colors.subTextColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _openAttendanceCalendar(
      BuildContext context, Subscription sub, AppLocalizations loc, AppColors colors) async {
    if (sub.userId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('noLinkedAccount')), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final viewer = authProv.currentUser;
    final isViewerStaff = authProv.isManager || viewer?.role == UserRole.employee;
    final isOwnProfile = viewer != null && viewer.id == sub.userId;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final user = await authProv.fetchUserById(sub.userId);

    if (context.mounted) Navigator.of(context, rootNavigator: true).pop(); // close loading dialog
    if (!context.mounted) return;

    // Managers and employees can always see full contact info + attendance.
    // A player looking at another player is blocked when that profile is
    // private — `fetchUserById` returns null in that case because the
    // security rules deny the read.
    if (!isViewerStaff && !isOwnProfile && user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.translate('privateProfileBlocked')),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonAttendanceScreen(
          personId: sub.userId,
          name: sub.playerName,
          email: user?.email ?? sub.userEmail,
          phone: user?.phone ?? '',
          nationalId: user?.nationalId ?? '',
          roleLabel: loc.translate('players'),
        ),
      ),
    );
  }

  void _showPlayerCodeDialog(BuildContext context, Subscription sub, AppLocalizations loc, AppColors colors) async {
    final subProv = Provider.of<SubscriptionProvider>(context, listen: false);
    final code = await subProv.ensureSubscriptionAttendanceCode(sub);
    final pubSubId = await subProv.ensurePublicSubscriptionId(sub);
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
            Text(sub.playerName, style: TextStyle(color: colors.textColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: QrImageView(
                data: code,
                version: QrVersions.auto,
                size: 200,
              ),
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
            Text('كود حضور اللاعب (Attendance Code)', style: TextStyle(color: colors.subTextColor, fontSize: 11)),
            if (pubSubId.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'معرّف الاشتراك: $pubSubId',
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

  @override
  Widget build(BuildContext context) {
    final subProv = Provider.of<SubscriptionProvider>(context);
    final finProv = Provider.of<FinancialProvider>(context, listen: false);
    final loc = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final visibleSubs = _filteredAndSorted(subProv.subscriptions);
    final canTakeAttendance = Provider.of<AuthProvider>(context, listen: false).canTakeAttendance;
    final isManager = Provider.of<AuthProvider>(context, listen: false).isManager;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: colors.scaffoldBg,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.primaryBlue),
        title: Text('${loc.translate('manageSubscribersAndSports')} (${subProv.subscriptions.length})',
            style: TextStyle(color: colors.textColor)),
        centerTitle: true,
        actions: [
          if (isManager)
            IconButton(
              icon: Icon(Icons.person_add_alt_1, color: colors.primaryBlue),
              tooltip: loc.translate('addPlayer'),
              onPressed: () => _showAddSubscriptionDialog(context, subProv, finProv, loc, colors),
            ),
          IconButton(
            icon: Icon(_sortAscending ? Icons.sort_by_alpha : Icons.sort, color: colors.primaryBlue),
            tooltip: loc.translate('sortByName'),
            onPressed: () => setState(() => _sortAscending = !_sortAscending),
          ),
          IconButton(
            icon: Icon(Icons.print_outlined, color: colors.primaryBlue),
            tooltip: loc.translate('printList'),
            onPressed: () => _showPrintPreview(context, visibleSubs, loc, colors),
          ),
          if (canTakeAttendance)
            IconButton(
              icon: Icon(Icons.qr_code_scanner_rounded, color: colors.primaryBlue),
              tooltip: loc.translate('scanAttendance'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AttendanceScannerScreen()),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(color: colors.textColor),
              decoration: InputDecoration(
                hintText: loc.translate('searchByPlayerName'),
                hintStyle: TextStyle(color: colors.subTextColor),
                prefixIcon: Icon(Icons.search, color: colors.subTextColor),
                filled: true,
                fillColor: colors.cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: subProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : visibleSubs.isEmpty
                    ? Center(
                        child: Text(loc.translate('noSubscribersYet'), style: TextStyle(color: colors.subTextColor)))
                    : ListView.builder(
                        itemCount: visibleSubs.length,
                        itemBuilder: (ctx, index) {
                          final sub = visibleSubs[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: colors.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.borderColor),
                            ),
                            child: ListTile(
                              onTap: () => _openAttendanceCalendar(context, sub, loc, colors),
                              leading: CircleAvatar(
                                backgroundColor: colors.primaryBlue.withOpacity(0.15),
                                child: Icon(sub.isActive ? Icons.person : Icons.person_off, color: colors.primaryBlue),
                              ),
                              title: Text(sub.playerName,
                                  style: TextStyle(color: colors.textColor, fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${loc.translate('sport')}: ${sub.sportName}\n${loc.translate('expiresOn')}: ${sub.endDate.toString().split(' ')[0]}'
                                '${sub.userEmail.trim().isNotEmpty ? '\n${sub.userEmail}' : ''}',
                                style: TextStyle(color: colors.subTextColor),
                              ),
                              isThreeLine: true,
                              trailing: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${sub.price} ${loc.translate('currency')}',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: colors.primaryBlue),
                                  ),
                                  SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      visualDensity: VisualDensity.compact,
                                      icon: Icon(Icons.qr_code, size: 18, color: colors.subTextColor),
                                      tooltip: loc.translate('showQrCode'),
                                      onPressed: () => _showPlayerCodeDialog(context, sub, loc, colors),
                                    ),
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

  void _showAddSubscriptionDialog(BuildContext context, SubscriptionProvider subProv, FinancialProvider finProv,
      AppLocalizations loc, AppColors colors) {
    final nameController = TextEditingController();
    final sportController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.cardBg,
        title: Text(loc.translate('addNewSubscriptionTitle'), style: TextStyle(color: colors.textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: colors.textColor),
              decoration: InputDecoration(
                labelText: loc.translate('subscriberName'),
                labelStyle: TextStyle(color: colors.subTextColor),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.borderColor)),
              ),
            ),
            TextField(
              controller: sportController,
              style: TextStyle(color: colors.textColor),
              decoration: InputDecoration(
                labelText: loc.translate('sportExampleHint'),
                labelStyle: TextStyle(color: colors.subTextColor),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.borderColor)),
              ),
            ),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: colors.textColor),
              decoration: InputDecoration(
                labelText: loc.translate('subscriptionAmount'),
                labelStyle: TextStyle(color: colors.subTextColor),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.borderColor)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.translate('cancel'), style: TextStyle(color: colors.subTextColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colors.primaryBlue, foregroundColor: colors.scaffoldBg),
            onPressed: () {
              if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                final price = double.tryParse(priceController.text) ?? 0.0;
                subProv.addSubscription(
                  playerName: nameController.text,
                  sportName: sportController.text.isEmpty ? loc.translate('general') : sportController.text,
                  price: price,
                  durationInDays: 30,
                  financialProvider: finProv,
                );
                Navigator.of(ctx).pop();
              }
            },
            child: Text(loc.translate('addAndSave')),
          ),
        ],
      ),
    );
  }
}
