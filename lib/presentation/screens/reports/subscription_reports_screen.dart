import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/financial_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';

class SubscriptionReportsScreen extends StatefulWidget {
  const SubscriptionReportsScreen({super.key});

  @override
  State<SubscriptionReportsScreen> createState() => _SubscriptionReportsScreenState();
}

class _SubscriptionReportsScreenState extends State<SubscriptionReportsScreen> {
  final _emailSearchController = TextEditingController();
  final _amountController = TextEditingController();

  int _selectedDurationMonths = 1;
  String _selectedDurationLabel = '1 Month';
  DateTime _startDate = DateTime.now();
  bool _isSearching = false;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _durationOptions = [
    {'months': 1, 'label': '1 Month (شهر واحد)'},
    {'months': 3, 'label': '3 Months (3 أشهر)'},
    {'months': 6, 'label': '6 Months (6 أشهر)'},
    {'months': 12, 'label': '1 Year (سنة كاملة)'},
  ];

  @override
  void dispose() {
    _emailSearchController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  DateTime _calculateExpiryDate(DateTime start, int months) {
    return DateTime(start.year, start.month + months, start.day);
  }

  Future<void> _handleSearchUser(SubscriptionProvider subProv, AppLocalizations loc) async {
    final email = _emailSearchController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isSearching = true);
    final user = await subProv.searchUserByEmail(email);
    setState(() => _isSearching = false);

    if (user != null) {
      await subProv.fetchUserSubscriptions(user.id);
    }
  }

  Future<void> _handleCreateSubscription(
    SubscriptionProvider subProv,
    FinancialProvider finProv,
    AppLocalizations loc,
  ) async {
    final user = subProv.searchedUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى البحث عن مستخدم أولاً'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال مبلغ دفع صحيح'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await subProv.addManagerSubscription(
      userId: user.id,
      userEmail: user.email,
      userName: user.name,
      durationMonths: _selectedDurationMonths,
      durationLabel: _selectedDurationLabel,
      amountPaid: amount,
      startDate: _startDate,
      financialProvider: finProv,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إضافة وتفعيل الاشتراك بنجاح للمستخدم ${user.name}'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _amountController.clear();
      await subProv.fetchUserSubscriptions(user.id);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل إضافة الاشتراك، يرجى المحاولة مرة أخرى'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context);
    final subProv = Provider.of<SubscriptionProvider>(context);
    final finProv = Provider.of<FinancialProvider>(context, listen: false);
    final loc = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    // Permission check: only Manager/Admin
    if (!authProv.isManager) {
      return Container(
        color: colors.scaffoldBg,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'عذراً، هذه الصفحة مخصصة لمدير الأكاديمية فقط إدارة الاشتراكات.',
              style: TextStyle(color: colors.subTextColor, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final searchedUser = subProv.searchedUser;
    final activeSub = subProv.userActiveSubscription;
    final history = subProv.userSubscriptionHistory;
    final calculatedExpiry = _calculateExpiryDate(_startDate, _selectedDurationMonths);
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Container(
      color: colors.scaffoldBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title Banner
                Text(
                  'إدارة الاشتراكات وإضافة الاشتراكات للمستخدمين',
                  style: TextStyle(color: colors.textColor, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'ابحث عن المستخدم بالبريد الإلكتروني وأضف له اشتراكاً مخصصاً بالمدة والمبلغ المحدد.',
                  style: TextStyle(color: colors.subTextColor, fontSize: 13),
                ),
                const SizedBox(height: 24),

                // Step 1: Search User by Email Card
                Card(
                  color: colors.cardBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '1. البحث عن المستخدم بالبريد الإلكتروني',
                          style: TextStyle(color: colors.textColor, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _emailSearchController,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(color: colors.textColor),
                                decoration: InputDecoration(
                                  hintText: 'أدخل البريد الإلكتروني (e.g. user@gmail.com)',
                                  hintStyle: TextStyle(color: colors.subTextColor, fontSize: 13),
                                  prefixIcon: Icon(Icons.search, color: colors.primaryBlue),
                                  filled: true,
                                  fillColor: colors.scaffoldBg,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: colors.borderColor),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primaryBlue,
                                foregroundColor: colors.scaffoldBg,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _isSearching ? null : () => _handleSearchUser(subProv, loc),
                              child: _isSearching
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: colors.scaffoldBg),
                                    )
                                  : const Text('بحث', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),

                        // Search Result Display
                        if (searchedUser != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colors.primaryBlue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.primaryBlue.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: colors.primaryBlue,
                                      child: Text(
                                        searchedUser.name.isNotEmpty ? searchedUser.name[0].toUpperCase() : 'U',
                                        style: TextStyle(color: colors.scaffoldBg, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            searchedUser.name,
                                            style: TextStyle(color: colors.textColor, fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          Text(
                                            searchedUser.email,
                                            style: TextStyle(color: colors.subTextColor, fontSize: 13),
                                          ),
                                          Text(
                                            'UID: ${searchedUser.id}',
                                            style: TextStyle(color: colors.subTextColor, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (activeSub?.isCurrentlyActive ?? false)
                                            ? Colors.green.withOpacity(0.15)
                                            : Colors.red.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        (activeSub?.isCurrentlyActive ?? false) ? 'نشط (Active)' : 'منتهي / غير مشترك',
                                        style: TextStyle(
                                          color: (activeSub?.isCurrentlyActive ?? false) ? Colors.green : Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Step 2: Subscription Details Form (Only if User is selected)
                if (searchedUser != null) ...[
                  Card(
                    color: colors.cardBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '2. تفاصيل الاشتراك الجديد للمستخدم',
                            style: TextStyle(color: colors.textColor, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),

                          // Duration Selection
                          Text('مدة الاشتراك (Duration):', style: TextStyle(color: colors.textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            value: _selectedDurationMonths,
                            dropdownColor: colors.cardBg,
                            style: TextStyle(color: colors.textColor),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: colors.scaffoldBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: colors.borderColor),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            items: _durationOptions.map((opt) {
                              return DropdownMenuItem<int>(
                                value: opt['months'] as int,
                                child: Text(opt['label'] as String, style: TextStyle(color: colors.textColor)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedDurationMonths = val;
                                  _selectedDurationLabel = _durationOptions.firstWhere((element) => element['months'] == val)['label'];
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // Amount Paid Input
                          Text('المبلغ المدفوع (Amount Paid - EGP):', style: TextStyle(color: colors.textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(color: colors.textColor),
                            decoration: InputDecoration(
                              hintText: 'أدخل المبلغ المطلوب (e.g. 500 أو 1200)',
                              hintStyle: TextStyle(color: colors.subTextColor, fontSize: 13),
                              prefixIcon: Icon(Icons.attach_money, color: colors.accentGreen),
                              filled: true,
                              fillColor: colors.scaffoldBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: colors.borderColor),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Dates Display
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.scaffoldBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.borderColor),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('تاريخ البداية (Start Date):', style: TextStyle(color: colors.subTextColor, fontSize: 12)),
                                    Text(dateFormat.format(_startDate), style: TextStyle(color: colors.textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('تاريخ الانتهاء التلقائي (Expiry Date):', style: TextStyle(color: colors.subTextColor, fontSize: 12)),
                                    Text(
                                      dateFormat.format(calculatedExpiry),
                                      style: TextStyle(color: colors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Submit Button
                          SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.accentGreen,
                                foregroundColor: colors.scaffoldBg,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _isSubmitting ? null : () => _handleCreateSubscription(subProv, finProv, loc),
                              icon: const Icon(Icons.check_circle_outline),
                              label: _isSubmitting
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.2, color: colors.scaffoldBg),
                                    )
                                  : const Text('حفظ وتفعيل الاشتراك للمستخدم', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Step 3: Subscription History
                  if (history.isNotEmpty) ...[
                    Card(
                      color: colors.cardBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'سجل الاشتراكات السابقة للمستخدم',
                              style: TextStyle(color: colors.textColor, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: history.length,
                              separatorBuilder: (_, __) => Divider(color: colors.borderColor),
                              itemBuilder: (ctx, idx) {
                                final sub = history[idx];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: sub.isCurrentlyActive
                                        ? Colors.green.withOpacity(0.15)
                                        : colors.subTextColor.withOpacity(0.15),
                                    child: Icon(
                                      sub.isCurrentlyActive ? Icons.check_circle : Icons.history,
                                      color: sub.isCurrentlyActive ? Colors.green : colors.subTextColor,
                                    ),
                                  ),
                                  title: Text(
                                    '${sub.durationLabel} - ${sub.amountPaid.toStringAsFixed(0)} EGP',
                                    style: TextStyle(color: colors.textColor, fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'من ${dateFormat.format(sub.startDate)} إلى ${dateFormat.format(sub.expiryDate)}',
                                    style: TextStyle(color: colors.subTextColor, fontSize: 12),
                                  ),
                                  trailing: Text(
                                    sub.status,
                                    style: TextStyle(
                                      color: sub.isCurrentlyActive ? Colors.green : colors.subTextColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
