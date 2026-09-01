import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/financial_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

/// Manager/Admin-only read-only revenue report: total income, a
/// breakdown by category (subscriptions, other income, etc.), and the
/// underlying transaction list. Built on the same real, already-tracked
/// [FinancialProvider] data used by the Expenses screen — this view just
/// focuses on income instead of mixing income/expenses with edit actions.
class RevenueReportsScreen extends StatelessWidget {
  const RevenueReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final finProv = Provider.of<FinancialProvider>(context);
    final loc = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final dateFmt = DateFormat('yyyy-MM-dd');

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

    final byCategory = <String, double>{};
    for (final t in incomeTx) {
      byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
    }
    final totalIncome = incomeTx.fold<double>(0, (sum, t) => sum + t.amount);

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
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colors.accentGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(loc.translate('totalRevenueLabel'),
                                style: TextStyle(color: colors.subTextColor, fontSize: 13)),
                            const SizedBox(height: 6),
                            Text('${totalIncome.toStringAsFixed(2)} EGP',
                                style: TextStyle(
                                    color: colors.accentGreen, fontSize: 28, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (byCategory.isNotEmpty) ...[
                        Text(loc.translate('revenueByCategoryLabel'),
                            style: TextStyle(color: colors.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        ...byCategory.entries.map((e) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: colors.cardBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: colors.borderColor),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(e.key, style: TextStyle(color: colors.textColor, fontWeight: FontWeight.w600)),
                                  Text('${e.value.toStringAsFixed(2)} EGP',
                                      style: TextStyle(color: colors.accentGreen, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )),
                        const SizedBox(height: 24),
                      ],

                      Text(loc.translate('revenueTransactionsLabel'),
                          style: TextStyle(color: colors.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      if (incomeTx.isEmpty)
                        Text(loc.translate('noTransactionsRecorded'), style: TextStyle(color: colors.subTextColor))
                      else
                        ...incomeTx.map((t) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colors.cardBg,
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
                                        Text(t.title, style: TextStyle(color: colors.textColor, fontWeight: FontWeight.bold)),
                                        Text('${t.category} • ${dateFmt.format(t.date)}',
                                            style: TextStyle(color: colors.subTextColor, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Text('+${t.amount.toStringAsFixed(2)}',
                                      style: TextStyle(color: colors.accentGreen, fontWeight: FontWeight.bold)),
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
}
