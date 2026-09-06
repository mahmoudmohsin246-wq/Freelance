import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import 'workspace_switcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';

class CustomSidebar extends StatelessWidget {
  final String currentRoute;
  final Function(String route) onSelectRoute;

  const CustomSidebar({
    super.key,
    required this.currentRoute,
    required this.onSelectRoute,
  });
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final loc = AppLocalizations.of(context);
    final isAdmin = _getIsAdmin(authProvider);
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.borderDark
                : AppColors.borderLight,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          const WorkspaceSwitcher(),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isAdmin ? AppColors.primary.withOpacity(0.1) : AppColors.accentOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isAdmin ? Icons.admin_panel_settings : Icons.person,
                      size: 18,
                      color: isAdmin ? AppColors.primary : AppColors.accentOrange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isAdmin ? loc.translate('roleAdmin') : loc.translate('roleNormalUser'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isAdmin ? AppColors.primary : AppColors.accentOrange,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {},
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.swap_horiz, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [

                _buildNavItem(
                  context,
                  route: 'branches',
                  icon: Icons.storefront_outlined,
                  activeIcon: Icons.storefront,
                  title: loc.translate('branchesAndGroups'),
                ),
                _buildNavItem(
                  context,
                  route: 'players',
                  icon: Icons.sports_soccer_outlined,
                  activeIcon: Icons.sports_soccer,
                  title: loc.translate('players'),
                ),
                _buildNavItem(
                  context,
                  route: 'packages',
                  icon: Icons.subscriptions_outlined,
                  activeIcon: Icons.subscriptions,
                  title: loc.translate('packagesAndSubscriptions'),
                ),
                _buildNavItem(
                  context,
                  route: 'profile',
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  title: loc.translate('profile'),
                ),

                if (isAdmin) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                    child: Text(
                      loc.translate('administrationSection'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  _buildNavItem(
                    context,
                    route: 'user_management',
                    icon: Icons.group_outlined,
                    activeIcon: Icons.group,
                    title: loc.translate('userManagement'),
                  ),
                  _buildNavItem(
                    context,
                    route: 'activity_log',
                    icon: Icons.history_outlined,
                    activeIcon: Icons.history,
                    title: loc.translate('activityLog'),
                  ),
                  _buildNavItem(
                    context,
                    route: 'subscription_reports',
                    icon: Icons.analytics_outlined,
                    activeIcon: Icons.analytics,
                    title: loc.translate('subscriptionReports'),
                  ),
                  _buildNavItem(
                    context,
                    route: 'revenue_reports',
                    icon: Icons.account_balance_wallet_outlined,
                    activeIcon: Icons.account_balance_wallet,
                    title: loc.translate('otherRevenueReport'),
                  ),
                  _buildNavItem(
                    context,
                    route: 'employees',
                    icon: Icons.badge_outlined,
                    activeIcon: Icons.badge,
                    title: loc.translate('employeeAttendanceAndSalaries'),
                  ),
                  _buildNavItem(
                    context,
                    route: 'expenses',
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long,
                    title: loc.translate('otherExpenses'),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.language, size: 20),
                  title: Text(loc.translate('language')),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      localeProvider.isArabic ? 'العربية' : 'English',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  onTap: () => localeProvider.toggleLanguage(),
                ),
                _buildNavItem(
                  context,
                  route: 'about',
                  icon: Icons.info_outline,
                  activeIcon: Icons.info,
                  title: loc.translate('aboutApp'),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.logout, color: Colors.orange, size: 20),
                  title: Text(
                    loc.translate('logout'),
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                  ),
                  onTap: () => authProvider.logout(),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 20),
                  title: Text(
                    loc.translate('deleteAccount'),
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                  ),
                  onTap: () => _showDeleteConfirmation(context, authProvider, loc),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required String route,
    required IconData icon,
    required IconData activeIcon,
    required String title,
  }) {
    final isSelected = currentRoute == route;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? AppColors.primary : Theme.of(context).iconTheme.color,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : null,
            fontSize: 14,
          ),
        ),
        onTap: () => onSelectRoute(route),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AuthProvider authProvider, AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.translate('deleteConfirmationTitle')),
        content: Text(loc.translate('deleteConfirmationDesc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.translate('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              authProvider.deleteAccount();
            },
            child: Text(loc.translate('confirmDelete')),
          ),
        ],
      ),
    );
  }

  bool _getIsAdmin(AuthProvider authProvider) {
    return authProvider.isManager;
  }
}