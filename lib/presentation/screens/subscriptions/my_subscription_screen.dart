import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart'; // تم إضافة حزمة الـ QR

import '../../providers/subscription_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

/// Read-only view of the signed-in user's subscription status and history.
/// Subscriptions are entirely managed by the Manager/Admin — normal users
/// cannot choose, purchase, or modify a plan here.
class MySubscriptionScreen extends StatelessWidget {
  const MySubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final subProv = Provider.of<SubscriptionProvider>(context);
    final dateFmt = DateFormat('yyyy-MM-dd');
    final active = subProv.userActiveSubscription;

    return Container(
      color: colors.scaffoldBg,
      child: subProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(loc.translate('mySubscriptionTitle'),
                          style: TextStyle(color: colors.textColor, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      if (active == null)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colors.cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: colors.borderColor),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.info_outline, color: colors.subTextColor, size: 32),
                              const SizedBox(height: 10),
                              Text(loc.translate('noActiveSubscriptionMsg'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: colors.textColor, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text(loc.translate('contactAdminToRenewMsg'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: colors.subTextColor, fontSize: 12)),
                            ],
                          ),
                        )
                      else ...[
                        // 1. كارت الـ QR Code مع عرض الـ ID في الأعلى
                        Container(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: colors.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.borderColor),
                          ),
                          child: Column(
                            children: [
                              // عرض الـ ID بوضوح أعلى الـ QR Code
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colors.primaryColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.badge_outlined, size: 18, color: colors.primaryColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      'ID: ${active.attendanceCode.trim().isNotEmpty ? active.attendanceCode.trim() : active.id.trim()}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: colors.primaryColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // توليد وعرض الـ QR Code
                              QrImageView(
                                data: active.attendanceCode.trim().isNotEmpty
                                    ? active.attendanceCode.trim()
                                    : active.id.trim(),
                                version: QrVersions.auto,
                                size: 180.0,
                                eyeStyle: QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: colors.textColor,
                                ),
                                dataModuleStyle: QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: colors.textColor,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              Text(
                                "امسح الرمز أو استخدم الـ ID للتسجيل اليدوي",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.subTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 2. كارت تفاصيل الاشتراك الحالي
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: colors.cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: active.isCurrentlyActive ? Colors.green.withOpacity(0.4) : Colors.redAccent.withOpacity(0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(active.durationLabel,
                                      style: TextStyle(color: colors.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (active.isCurrentlyActive ? Colors.green : Colors.redAccent).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      loc.translate(active.isCurrentlyActive ? 'statusActive' : 'statusExpired'),
                                      style: TextStyle(
                                        color: active.isCurrentlyActive ? Colors.green : Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              _row(loc.translate('startDateLabel'), dateFmt.format(active.startDate), colors),
                              const SizedBox(height: 8),
                              _row(loc.translate('expiryDateLabel'), dateFmt.format(active.expiryDate), colors),
                              const SizedBox(height: 8),
                              _row(loc.translate('amountPaidColumnLabel'), active.amountPaid.toStringAsFixed(0), colors),
                              if (!active.isCurrentlyActive) ...[
                                const SizedBox(height: 14),
                                Text(loc.translate('contactAdminToRenewMsg'),
                                    style: TextStyle(color: colors.subTextColor, fontSize: 12)),
                              ],
                            ],
                          ),
                        ),
                      ],

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
                                  Text(s.amountPaid.toStringAsFixed(0),
                                      style: TextStyle(color: colors.textColor, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _row(String label, String value, AppColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.subTextColor, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.textColor, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}