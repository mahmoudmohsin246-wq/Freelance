import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/financial_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';







class RevenueReportsScreen extends StatefulWidget {
  const RevenueReportsScreen({super.key});

  @override
  State<RevenueReportsScreen> createState() => _RevenueReportsScreenState();
}

class _RevenueReportsScreenState extends State<RevenueReportsScreen> {

  String? _expandedMonthKey;

  String _monthKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final finProv = Provider.of<FinancialProvider>(context);
    final loc = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final dateFmt = DateFormat('yyyy-MM-dd');
    final monthFmt = DateFormat.yMMMM(loc.locale.languageCode);

    if (!authProv.isManager) {
      return Container(
        color: colors.scaffoldBg,
        child: Center(
          child: Text(loc.translate('genericError'), style: TextStyle(color: colors.subTextColor)),
        ),
      );
    }

    final incomeTx = finProv.transactions.where((t) => t.isIncome).toList()
      ..sort((a, b) => b.date.compareTo(a.date));




    final Map<String, List<dynamic>> byMonth = {};
    for (final t in incomeTx) {
      final key = _monthKey(t.date);
      (byMonth[key] ??= []).add(t);
    }
    final monthKeys = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));

    return Container(
      color: colors.scaffoldBg,
      child: finProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(loc.translate('monthlyRevenueLabel'),
                          style: TextStyle(color: colors.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      if (monthKeys.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(loc.translate('noTransactionsRecorded'),
                                style: TextStyle(color: colors.subTextColor)),
                          ),
                        )
                      else
                        ...monthKeys.map((key) {
                          final txs = byMonth[key]!;
                          final monthTotal = txs.fold<double>(0, (sum, t) => sum + (t.amount as double));
                          final monthDate = txs.first.date as DateTime;
                          final isExpanded = _expandedMonthKey == key;

                          final byCategory = <String, double>{};
                          for (final t in txs) {
                            byCategory[t.category as String] =
                                (byCategory[t.category as String] ?? 0) + (t.amount as double);
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: colors.cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colors.borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => setState(() => _expandedMonthKey = isExpanded ? null : key),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: colors.accentGreen.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(Icons.calendar_month_outlined, color: colors.accentGreen, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                monthFmt.format(monthDate),
                                                style: TextStyle(
                                                    color: colors.textColor, fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                loc.translate('transactionsCountLabel').replaceFirst('{count}', txs.length.toString()),
                                                style: TextStyle(color: colors.subTextColor, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${monthTotal.toStringAsFixed(2)} ${loc.translate('egpCurrencyAbbrev')}',
                                          style: TextStyle(
                                              color: colors.accentGreen, fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        Icon(
                                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                          color: colors.subTextColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isExpanded)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Divider(color: colors.borderColor),
                                        const SizedBox(height: 8),
                                        Text(loc.translate('revenueByCategoryLabel'),
                                            style: TextStyle(
                                                color: colors.textColor, fontSize: 13, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        ...byCategory.entries.map((e) => Container(
                                              margin: const EdgeInsets.only(bottom: 6),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: colors.scaffoldBg,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: colors.borderColor),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(e.key, style: TextStyle(color: colors.textColor, fontWeight: FontWeight.w600)),
                                                  Text('${e.value.toStringAsFixed(2)} ${loc.translate('egpCurrencyAbbrev')}',
                                                      style: TextStyle(color: colors.accentGreen, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            )),
                                        const SizedBox(height: 12),
                                        Text(loc.translate('revenueTransactionsLabel'),
                                            style: TextStyle(
                                                color: colors.textColor, fontSize: 13, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        ...txs.map((t) => Container(
                                              margin: const EdgeInsets.only(bottom: 8),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: colors.scaffoldBg,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: colors.borderColor),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.arrow_downward, color: colors.accentGreen, size: 18),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(t.title as String,
                                                            style: TextStyle(color: colors.textColor, fontWeight: FontWeight.bold)),
                                                        Text('${t.category} • ${dateFmt.format(t.date as DateTime)}',
                                                            style: TextStyle(color: colors.subTextColor, fontSize: 12)),
                                                      ],
                                                    ),
                                                  ),
                                                  Text('+${(t.amount as double).toStringAsFixed(2)}',
                                                      style: TextStyle(color: colors.accentGreen, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            )),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}