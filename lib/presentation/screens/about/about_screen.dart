import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.translate('aboutApp'),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Sports Academy Management Platform',
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.sports, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sports Academy Enterprise System',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Version 1.0.0 (Production Architecture)',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'A multi-workspace, role-based sports academy management system designed for scale. Supports multi-branch operations, athlete rosters, attendance tracking, financial accounting, revenue auditing, and SaaS tiering.',
                      textAlign: TextAlign.center,
                      style: TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                    title: Text(loc.translate('privacyPolicy')),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showDialogInfo(
                      context,
                      loc.translate('privacyPolicy'),
                      'Our Privacy Policy guarantees 100% data isolation across academy workspaces. Your member information, financial reports, and activity logs are encrypted and strictly guarded by role-based access control.',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.gavel_outlined, color: AppColors.primary),
                    title: Text(loc.translate('termsAndConditions')),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showDialogInfo(
                      context,
                      loc.translate('termsAndConditions'),
                      'By utilizing the Sports Academy Management System, workspace administrators agree to maintain accurate records, comply with regional labor policies for employee attendance & salaries, and honor student athlete privacy.',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.contact_support_outlined, color: AppColors.primary),
                    title: Text(loc.translate('contactUs')),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showDialogInfo(
                      context,
                      loc.translate('contactUs'),
                      'Have questions or need backend API integration assistance?\n\nEmail: support@sportsacademy.com\nPhone: +1 (800) 555-SPORTS\nWebsite: https://sportsacademy.com',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDialogInfo(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body, style: const TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
