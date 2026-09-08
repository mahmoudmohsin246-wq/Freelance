import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/financial_provider.dart';
import '../../providers/branches_provider.dart';
import '../../../core/services/push_notification_service.dart';

import '../players/players_screen.dart';
import '../expenses/expenses_screen.dart';
import '../profile/profile_screen.dart';
import '../workspaces/workspace_switcher_screen.dart';
import '../branches/branches_screen_impl.dart';
import '../subscriptions/manager_subscriptions_screen.dart';
import '../subscriptions/my_subscription_screen.dart';
import '../user_management/user_management_screen.dart';
import '../activity_log/activity_log_screen.dart';
import '../reports/subscription_reports_screen.dart';
import '../reports/revenue_reports_screen.dart';
import '../about/about_screen_impl.dart';
import '../employees/employee_attendance_screen_impl.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  bool _isWide = false;
  bool _isResendingEmail = false;

  late AppColors _colors;
  Color get scaffoldBg => _colors.scaffoldBg;
  Color get drawerBg => _colors.drawerBg;
  Color get cardBg => _colors.cardBg;
  Color get primaryBlue => _colors.primaryBlue;
  Color get textColor => _colors.textColor;
  Color get subTextColor => _colors.subTextColor;
  Color get borderColor => _colors.borderColor;

  @override
  void initState() {
    super.initState();
    PushNotificationService.instance.notificationTapNotifier.addListener(_onPushNotificationTapped);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProv = Provider.of<AuthProvider>(context, listen: false);
      final user = authProv.currentUser;
      if (user != null) {
        final notifProv = Provider.of<NotificationProvider>(context, listen: false);
        final subProv = Provider.of<SubscriptionProvider>(context, listen: false);
        notifProv.fetchNotifications(user.id);
        subProv.fetchUserSubscriptions(user.id, notificationProvider: notifProv);

        // Covers a cold start where the app was launched by tapping a push
        // notification (the tap happened before this screen, and this
        // listener, existed).
        if (PushNotificationService.instance.consumePendingNotificationTap()) {
          _onPushNotificationTapped();
        }


        if (authProv.isManager || authProv.canTakeAttendance) {
          subProv.loadSubscriptions();
        }
        if (authProv.isManager) {
          Provider.of<FinancialProvider>(context, listen: false).loadFinancialData();
        }



        Provider.of<BranchesProvider>(context, listen: false).loadBranches();
      }
    });
  }

  @override
  void dispose() {
    PushNotificationService.instance.notificationTapNotifier.removeListener(_onPushNotificationTapped);
    super.dispose();
  }

  void _onPushNotificationTapped() {
    if (!mounted) return;
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    if (authProv.currentUser == null) return;
    final notifProv = Provider.of<NotificationProvider>(context, listen: false);
    // Opening the same in-app notification center the bell icon already
    // opens — push is an additional delivery channel, not a new screen.
    _showNotificationsSheet(context, notifProv, authProv);
  }

  void _showSendMessageDialog(BuildContext context, NotificationProvider notifProv, AuthProvider authProv) {
    final loc = AppLocalizations.of(context);
    final isManager = authProv.isManager;
    if (!isManager) return;

    final emailCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    bool isBroadcast = false;
    bool sending = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.send_rounded, color: primaryBlue),
              const SizedBox(width: 8),
              Text(loc.translate('sendMessageNotifTitle'), style: TextStyle(color: textColor, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ChoiceChip(
                      label: Text(loc.translate('specificUserChip')),
                      selected: !isBroadcast,
                      selectedColor: primaryBlue.withValues(alpha: 0.2),
                      onSelected: (val) => setDialogState(() => isBroadcast = false),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(loc.translate('broadcastAllChip')),
                      selected: isBroadcast,
                      selectedColor: primaryBlue.withValues(alpha: 0.2),
                      onSelected: (val) => setDialogState(() => isBroadcast = true),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!isBroadcast) ...[
                  TextField(
                    controller: emailCtrl,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: loc.translate('recipientEmailLabel'),
                      labelStyle: TextStyle(color: subTextColor),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: titleCtrl,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: loc.translate('messageTitleLabel'),
                    labelStyle: TextStyle(color: subTextColor),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageCtrl,
                  maxLines: 3,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: loc.translate('messageBodyLabel'),
                    labelStyle: TextStyle(color: subTextColor),
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (errorMsg != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    errorMsg!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.pop(ctx),
              child: Text(loc.translate('cancel'), style: TextStyle(color: subTextColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
              onPressed: sending
                  ? null
                  : () async {
                      if (titleCtrl.text.trim().isEmpty || messageCtrl.text.trim().isEmpty) {
                        setDialogState(() => errorMsg = loc.translate('pleaseEnterTitleAndBody'));
                        return;
                      }
                      setDialogState(() {
                        sending = true;
                        errorMsg = null;
                      });

                      final sender = authProv.currentUser;
                      final senderId = sender?.id ?? '';
                      final senderName = sender?.name ?? loc.translate('academyManagementLabel');

                      try {
                        if (isBroadcast) {
                          await authProv.fetchAllUsers();
                          final userIds = authProv.allUsers.map((u) => u.id).toList();
                          await notifProv.sendBroadcastNotification(
                            targetUserIds: userIds,
                            title: titleCtrl.text.trim(),
                            message: messageCtrl.text.trim(),
                            senderId: senderId,
                            senderName: senderName,
                          );
                        } else {
                          await notifProv.sendNotificationByEmail(
                            recipientEmail: emailCtrl.text.trim(),
                            title: titleCtrl.text.trim(),
                            message: messageCtrl.text.trim(),
                            senderId: senderId,
                            senderName: senderName,
                          );
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(loc.translate('notificationSentSuccess')),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        final msg = e.toString();
                        setDialogState(() {
                          sending = false;
                          if (msg.contains('enterValidEmail')) {
                            errorMsg = loc.translate('enterValidEmailMsg');
                          } else if (msg.contains('noAccountWithEmail')) {
                            errorMsg = loc.translate('noAccountWithEmailMsg');
                          } else {
                            errorMsg = '${loc.translate('sendErrorPrefix')}: $e';
                          }
                        });
                      }
                    },
              child: sending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(loc.translate('sendButton')),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context, NotificationProvider notifProv, AuthProvider authProv) {
    final loc = AppLocalizations.of(context);
    final user = authProv.currentUser;
    if (user != null) {
      notifProv.fetchNotifications(user.id);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer<NotificationProvider>(
          builder: (ctx, nProv, _) {
            final list = nProv.notifications;
            final unread = nProv.unreadCount;
            final isManager = authProv.isManager;

            return SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.translate('notificationsAndMessagesTitle'),
                          style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            if (unread > 0 && user != null)
                              TextButton(
                                onPressed: () => nProv.markAllAsRead(user.id),
                                child: Text(loc.translate('markAllAsReadLabel'), style: const TextStyle(fontSize: 12)),
                              ),
                            if (isManager)
                              IconButton(
                                icon: Icon(Icons.add_comment_outlined, color: primaryBlue),
                                tooltip: loc.translate('sendNotificationToUsersLabel'),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _showSendMessageDialog(context, nProv, authProv);
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (list.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: Text(loc.translate('noNotificationsCurrently'), style: TextStyle(color: subTextColor, fontSize: 14)),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: list.length,
                          separatorBuilder: (_, __) => Divider(color: borderColor),
                          itemBuilder: (ctx, index) {
                            final notif = list[index];
                            final timeStr = DateFormat('yyyy-MM-dd HH:mm').format(notif.createdAt);
                            final isBroadcast = notif.type == 'broadcast';
                            final isReminder = notif.type == 'subscription_reminder' || notif.type == 'subscription_expired';

                            return Container(
                              decoration: BoxDecoration(
                                color: notif.isRead ? Colors.transparent : primaryBlue.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: notif.isRead
                                      ? subTextColor.withValues(alpha: 0.15)
                                      : (isBroadcast ? Colors.purple.withValues(alpha: 0.15) : primaryBlue.withValues(alpha: 0.15)),
                                  child: Icon(
                                    isReminder
                                        ? Icons.warning_amber_rounded
                                        : (isBroadcast ? Icons.campaign_rounded : Icons.mark_email_unread_outlined),
                                    color: isReminder
                                        ? Colors.amber
                                        : (isBroadcast ? Colors.purpleAccent : primaryBlue),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notif.title.isNotEmpty ? notif.title : loc.translate('academyNotificationDefaultTitle'),
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (isBroadcast)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(loc.translate('announcementLabel'), style: const TextStyle(fontSize: 10, color: Colors.purpleAccent)),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      notif.message,
                                      style: TextStyle(color: subTextColor, fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (notif.senderName.isNotEmpty)
                                          Text('${loc.translate('fromLabel')}: ${notif.senderName}', style: TextStyle(color: primaryBlue, fontSize: 10)),
                                        Text(timeStr, style: TextStyle(color: subTextColor, fontSize: 10)),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  if (user != null && !notif.isRead) {
                                    nProv.markAsRead(user.id, notif.id);
                                  }
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      backgroundColor: cardBg,
                                      title: Text(notif.title, style: TextStyle(color: textColor)),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(notif.message, style: TextStyle(color: textColor, fontSize: 14)),
                                          const SizedBox(height: 12),
                                          Text('${loc.translate('dateLabel')}: $timeStr', style: TextStyle(color: subTextColor, fontSize: 11)),
                                          if (notif.senderName.isNotEmpty)
                                            Text('${loc.translate('senderLabel')}: ${notif.senderName}', style: TextStyle(color: subTextColor, fontSize: 11)),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text(loc.translate('close')),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
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

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final isManager = authProv.isManager;
    final loc = AppLocalizations.of(context);
    _colors = AppColors.of(context);

    final screens = <Widget>[
      const BranchesScreenImpl(),
      const ProfileScreen(),
      const WorkspaceSwitcherScreen(),
      const PlayersScreen(),
      isManager
          ? const ManagerSubscriptionsScreen()
          : const MySubscriptionScreen(),
      const UserManagementScreen(),
      const ActivityLogScreen(),
      const SubscriptionReportsScreen(),
      const RevenueReportsScreen(),
      const EmployeeAttendanceScreenImpl(),
      const ExpensesScreen(),
      const AboutAppScreenImpl(),
    ];

    final isWide = Responsive.isWideScreen(context);
    _isWide = isWide;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        title: Text(
          _getTitleByIndex(_selectedIndex, loc, isManager),
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              context.watch<ThemeProvider>().isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: primaryBlue,
            ),
            tooltip: loc.translate('toggleTheme'),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
          IconButton(
            icon: Icon(Icons.language, color: primaryBlue),
            tooltip: loc.translate('changeLanguage'),
            onPressed: () {
              final localeProv = Provider.of<LocaleProvider>(context, listen: false);
              localeProv.toggleLanguage();
            },
          ),
          Consumer<NotificationProvider>(
            builder: (ctx, notifProv, _) {
              final unread = notifProv.unreadCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_outlined, color: primaryBlue),
                    tooltip: loc.translate('notificationsLabel'),
                    onPressed: () => _showNotificationsSheet(context, notifProv, authProv),
                  ),
                  if (unread > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$unread',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      drawer: isWide ? null : _buildDrawer(context, isManager, authProv, loc),
      body: Column(
        children: [
          Consumer<AuthProvider>(
            builder: (ctx, authP, _) {
              if (authP.isEmailVerified) return const SizedBox.shrink();
              return _buildVerifyEmailBanner(context, authP, loc);
            },
          ),
          Expanded(
            child: isWide
                ? Row(
                    children: [
                      SizedBox(
                        width: 280,
                        child: _buildSidebarContent(context, isManager, authProv, loc),
                      ),
                      VerticalDivider(width: 1, color: borderColor),
                      Expanded(child: screens[_selectedIndex]),
                    ],
                  )
                : screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyEmailBanner(BuildContext context, AuthProvider authProv, AppLocalizations loc) {
    return Material(
      color: Colors.amber.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.mark_email_unread_outlined, color: Colors.amber, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          loc.translate('verifyEmailBanner'),
                          style: TextStyle(color: textColor, fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: TextButton(
                          onPressed: () async {
                            await authProv.refreshEmailVerified();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(authProv.isEmailVerified
                                    ? loc.translate('emailVerifiedSuccessMsg')
                                    : loc.translate('emailNotVerifiedYetMsg')),
                                backgroundColor: authProv.isEmailVerified ? Colors.green : Colors.amber.shade800,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Text(loc.translate('iVerifiedRefresh'), style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                      Flexible(
                        child: TextButton(
                          onPressed: _isResendingEmail
                              ? null
                              : () async {
                                  setState(() => _isResendingEmail = true);
                                  final sent = await authProv.resendVerificationEmail();
                                  if (mounted) setState(() => _isResendingEmail = false);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(loc.translate(
                                          sent ? 'verificationEmailSent' : (authProv.errorMessage ?? 'genericError'))),
                                      backgroundColor: sent ? Colors.green : Colors.redAccent,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                          child: _isResendingEmail
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(loc.translate('resendVerificationEmail'), style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
            return Row(
              children: [
                const Icon(Icons.mark_email_unread_outlined, color: Colors.amber, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    loc.translate('verifyEmailBanner'),
                    style: TextStyle(color: textColor, fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await authProv.refreshEmailVerified();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(authProv.isEmailVerified
                            ? loc.translate('emailVerifiedSuccessMsg')
                            : loc.translate('emailNotVerifiedYetMsg')),
                        backgroundColor: authProv.isEmailVerified ? Colors.green : Colors.amber.shade800,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Text(loc.translate('iVerifiedRefresh'), style: const TextStyle(fontSize: 12)),
                ),
                TextButton(
                  onPressed: _isResendingEmail
                      ? null
                      : () async {
                          setState(() => _isResendingEmail = true);
                          final sent = await authProv.resendVerificationEmail();
                          if (mounted) setState(() => _isResendingEmail = false);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(loc.translate(
                                  sent ? 'verificationEmailSent' : (authProv.errorMessage ?? 'genericError'))),
                              backgroundColor: sent ? Colors.green : Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                  child: _isResendingEmail
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(loc.translate('resendVerificationEmail'), style: const TextStyle(fontSize: 12)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDrawer(
      BuildContext context, bool isManager, AuthProvider authProv, AppLocalizations loc) {
    return Drawer(
      child: _buildSidebarContent(context, isManager, authProv, loc),
    );
  }

  Widget _buildSidebarContent(
      BuildContext context, bool isManager, AuthProvider authProv, AppLocalizations loc) {
    return Container(
        color: drawerBg,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 40),
          children: [
            Consumer<SubscriptionProvider>(
              builder: (ctx, subProv, _) {
                final active = subProv.userActiveSubscription;
                final statusLabel = active == null
                    ? loc.translate('noSubscriptionShort')
                    : loc.translate(active.isCurrentlyActive ? 'statusActive' : 'statusExpired');
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.translate('currentSubscription'),
                              style: TextStyle(color: subTextColor, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(statusLabel,
                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        onPressed: () {
                          setState(() => _selectedIndex = 4);
                          if (!_isWide) Navigator.pop(context);
                        },
                        child: Text(loc.translate(isManager ? 'manageButton' : 'viewButton'),
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            Text(loc.translate('basicSection'),
                style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            _drawerTile(Icons.grid_view_rounded, loc.translate('branchesAndGroups'), primaryBlue, 0),
            _drawerTile(Icons.person_outline, loc.translate('profile'), Colors.amber, 1),
            _drawerTile(Icons.groups_outlined, loc.translate('publicPlayersList'), Colors.tealAccent, 3),
            _drawerTile(Icons.star_outline, loc.translate('packagesAndSubscriptions'), Colors.amberAccent, 4),

            if (isManager) ...[
              const SizedBox(height: 16),
              Text(loc.translate('managementSection'),
                  style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              _drawerTile(Icons.admin_panel_settings_outlined, loc.translate('userManagement'), Colors.indigoAccent, 5),
              _drawerTile(Icons.history, loc.translate('activityLog'), Colors.pinkAccent, 6),
              _drawerTile(Icons.receipt_long, loc.translate('subscriptionReports'), Colors.greenAccent, 7),
              _drawerTile(Icons.bar_chart, loc.translate('otherRevenueReport'), Colors.pink, 8),
              _drawerTile(Icons.badge_outlined, loc.translate('employeeAttendanceAndSalaries'), Colors.teal, 9),
              _drawerTile(Icons.account_balance_wallet_outlined, loc.translate('otherExpenses'), Colors.redAccent, 10),
            ],

            const SizedBox(height: 16),
            Text(loc.translate('aboutApp'),
                style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _drawerTile(Icons.info_outline, loc.translate('aboutAppAndPolicies'), Colors.blueGrey, 11),

            Divider(color: borderColor),

            ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
              title: Text(loc.translate('deleteAccount'),
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
              onTap: () {
                if (!_isWide) Navigator.pop(context);
                _confirmDeleteAccount(context, authProv, loc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.orangeAccent),
              title: Text(loc.translate('logout'),
                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 14)),
              onTap: () {
                authProv.logout();
              },
            ),
          ],
        ),
      );
  }

  Widget _drawerTile(IconData icon, String title, Color iconColor, int index) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      selected: isSelected,
      selectedTileColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? primaryBlue : textColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      onTap: () {
        setState(() => _selectedIndex = index);
        if (!_isWide) Navigator.pop(context);
      },
    );
  }

  String _getTitleByIndex(int index, AppLocalizations loc, bool isManager) {
    switch (index) {
      case 0: return loc.translate('branchesAndGroups');
      case 1: return loc.translate('profile');
      case 2: return loc.translate('workspacesTitle');
      case 3: return loc.translate('manageAllPlayersTitle');
      case 4: return loc.translate(isManager ? 'manageSubscriptionsTitle' : 'mySubscriptionTitle');
      case 5: return loc.translate('userManagement');
      case 6: return loc.translate('activityLog');
      case 7: return loc.translate('subscriptionReports');
      case 8: return loc.translate('otherRevenueReport');
      case 9: return loc.translate('employeeAttendanceAndSalaries');
      case 10: return loc.translate('otherExpenses');
      case 11: return loc.translate('aboutApp');
      default: return loc.translate('appName');
    }
  }

  void _confirmDeleteAccount(BuildContext context, AuthProvider auth, AppLocalizations loc) {
    final passwordCtrl = TextEditingController();
    bool submitting = false;
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: cardBg,
          title: Text(loc.translate('deleteConfirmationTitle'), style: TextStyle(color: textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.translate('deleteConfirmationDesc'),
                style: TextStyle(color: subTextColor),
              ),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
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
                      final ok = await auth.deleteAccount(password: passwordCtrl.text);
                      if (!ctx.mounted) return;
                      if (ok) {
                        Navigator.pop(ctx);
                      } else {
                        setDialogState(() {
                          submitting = false;
                          error = loc.translate(auth.errorMessage ?? 'genericError');
                        });
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(loc.translate('confirmDelete'), style: const TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}

class BranchesScreenPlaceholder extends StatelessWidget {
  final AppLocalizations loc;
  const BranchesScreenPlaceholder({super.key, required this.loc});
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: Text(loc.translate('noBranchesYet'), style: TextStyle(color: colors.subTextColor, fontSize: 16)),
    );
  }
}

class SubscriptionsScreenPlaceholder extends StatelessWidget {
  final AppLocalizations loc;
  const SubscriptionsScreenPlaceholder({super.key, required this.loc});
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: Text(loc.translate('choosePackageDesc'), style: TextStyle(color: colors.subTextColor)),
    );
  }
}

class AttendanceScreenPlaceholder extends StatelessWidget {
  final AppLocalizations loc;
  const AttendanceScreenPlaceholder({super.key, required this.loc});
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: Text(loc.translate('employeeAttendanceAndSalaries'), style: TextStyle(color: colors.subTextColor)),
    );
  }
}

class AboutAppPlaceholder extends StatelessWidget {
  final AppLocalizations loc;
  const AboutAppPlaceholder({super.key, required this.loc});
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: Text(loc.translate('aboutAppPlaceholderDesc'), style: TextStyle(color: colors.subTextColor)),
    );
  }
}