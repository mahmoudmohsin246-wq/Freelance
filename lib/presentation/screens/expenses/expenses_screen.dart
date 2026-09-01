import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/financial_provider.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final financialProv = Provider.of<FinancialProvider>(context);
    final loc = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: colors.scaffoldBg,
        elevation: 0,
        title: Text(loc.translate('manageFinancesAndExpenses'), style: TextStyle(color: colors.textColor)),
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.primaryBlue),
      ),
      body: financialProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      _buildSummaryCard(
                        colors,
                        loc.translate('revenue'),
                        '${financialProv.totalIncome.toStringAsFixed(2)} ج.م',
                        colors.accentGreen,
                      ),
                      const SizedBox(width: 8),
                      _buildSummaryCard(
                        colors,
                        loc.translate('expenses'),
                        '${financialProv.totalExpenses.toStringAsFixed(2)} ج.م',
                        Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      _buildSummaryCard(
                        colors,
                        loc.translate('netBalance'),
                        '${financialProv.netBalance.toStringAsFixed(2)} ج.م',
                        financialProv.netBalance >= 0 ? colors.primaryBlue : Colors.orangeAccent,
                      ),
                    ],
                  ),
                ),
                Divider(color: colors.borderColor, height: 1),
                Expanded(
                  child: financialProv.transactions.isEmpty
                      ? Center(
                          child: Text(loc.translate('noTransactionsRecorded'),
                              style: TextStyle(color: colors.subTextColor)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: financialProv.transactions.length,
                          itemBuilder: (ctx, index) {
                            final item = financialProv.transactions[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: colors.cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.borderColor),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor:
                                      (item.isIncome ? colors.accentGreen : Colors.redAccent).withOpacity(0.15),
                                  child: Icon(
                                    item.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: item.isIncome ? colors.accentGreen : Colors.redAccent,
                                  ),
                                ),
                                title: Text(item.title, style: TextStyle(color: colors.textColor)),
                                subtitle: Text(
                                  '${item.category} • ${DateFormat('yyyy/MM/dd').format(item.date)}',
                                  style: TextStyle(color: colors.subTextColor, fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${item.isIncome ? '+' : '-'}${item.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: item.isIncome ? colors.accentGreen : Colors.redAccent,
                                        fontSize: 15,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline, color: colors.subTextColor, size: 20),
                                      onPressed: () => financialProv.deleteTransaction(item.id),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: colors.primaryBlue,
        foregroundColor: colors.scaffoldBg,
        onPressed: () => _showAddTransactionDialog(context, loc, colors),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(AppColors colors, String title, String value, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderColor),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context, AppLocalizations loc, AppColors colors) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final categoryController = TextEditingController();
    bool isIncome = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: colors.cardBg,
          title: Text(loc.translate('addNewTransaction'), style: TextStyle(color: colors.textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: TextStyle(color: colors.textColor),
                decoration: InputDecoration(
                  labelText: loc.translate('descriptionLabel'),
                  labelStyle: TextStyle(color: colors.subTextColor),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.borderColor)),
                ),
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: colors.textColor),
                decoration: InputDecoration(
                  labelText: loc.translate('amount'),
                  labelStyle: TextStyle(color: colors.subTextColor),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.borderColor)),
                ),
              ),
              TextField(
                controller: categoryController,
                style: TextStyle(color: colors.textColor),
                decoration: InputDecoration(
                  labelText: loc.translate('categoryHint'),
                  labelStyle: TextStyle(color: colors.subTextColor),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.borderColor)),
                ),
              ),
              Row(
                children: [
                  Text(loc.translate('transactionType'), style: TextStyle(color: colors.textColor)),
                  Switch(
                    value: isIncome,
                    onChanged: (val) => setState(() => isIncome = val),
                    activeColor: colors.accentGreen,
                  ),
                  Text(isIncome ? loc.translate('income') : loc.translate('expense'),
                      style: TextStyle(color: colors.textColor)),
                ],
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
                if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                  final amount = double.tryParse(amountController.text) ?? 0.0;
                  Provider.of<FinancialProvider>(context, listen: false).addTransaction(
                    title: titleController.text,
                    amount: amount,
                    isIncome: isIncome,
                    category: categoryController.text.isEmpty
                        ? loc.translate('generalCategory')
                        : categoryController.text,
                  );
                  Navigator.of(ctx).pop();
                }
              },
              child: Text(loc.translate('save')),
            ),
          ],
        ),
      ),
    );
  }
}
