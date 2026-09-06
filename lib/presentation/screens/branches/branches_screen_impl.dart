import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/branches_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

class BranchesScreenImpl extends StatelessWidget {
  const BranchesScreenImpl({super.key});

  void _showAddBranchDialog(BuildContext context, AppLocalizations loc, AppColors colors) {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.cardBg,
        title: Text(loc.translate('addBranchTitle'), style: TextStyle(color: colors.textColor)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                style: TextStyle(color: colors.textColor),
                decoration: InputDecoration(
                  labelText: loc.translate('branchName'),
                  labelStyle: TextStyle(color: colors.subTextColor),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? loc.translate('branchNameRequired') : null,
              ),
              TextFormField(
                controller: addressCtrl,
                style: TextStyle(color: colors.textColor),
                decoration: InputDecoration(
                  labelText: loc.translate('branchAddress'),
                  labelStyle: TextStyle(color: colors.subTextColor),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.translate('cancel'), style: TextStyle(color: colors.subTextColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colors.primaryBlue),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Provider.of<BranchesProvider>(context, listen: false)
                    .addBranch(nameCtrl.text.trim(), address: addressCtrl.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(loc.translate('branchAdded')),
                    backgroundColor: colors.accentGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(loc.translate('addBranch'), style: TextStyle(color: colors.onPrimary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branchesProv = context.watch<BranchesProvider>();
    final isManager = context.watch<AuthProvider>().isManager;
    final loc = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    return Container(
      color: colors.scaffoldBg,
      child: Column(
        children: [
          if (isManager)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryBlue,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showAddBranchDialog(context, loc, colors),
                  icon: const Icon(Icons.add),
                  label: Text(loc.translate('addBranch'), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colors.subTextColor, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(loc.translate('managersOnlyHint'),
                        style: TextStyle(color: colors.subTextColor, fontSize: 12)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: branchesProv.isLoading
                ? Center(child: CircularProgressIndicator(color: colors.primaryBlue))
                : branchesProv.branches.isEmpty
                    ? Center(
                        child: Text(loc.translate('noBranchesYet'),
                            style: TextStyle(color: colors.subTextColor, fontSize: 16)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: branchesProv.branches.length,
                        itemBuilder: (ctx, index) {
                          final branch = branchesProv.branches[index];
                          return Card(
                            color: colors.cardBg,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: colors.primaryBlue.withOpacity(0.13),
                                child: Icon(Icons.storefront_outlined, color: colors.primaryBlue),
                              ),
                              title: Text(branch.name,
                                  style: TextStyle(color: colors.textColor, fontWeight: FontWeight.bold)),
                              subtitle: branch.address.isNotEmpty
                                  ? Text(branch.address, style: TextStyle(color: colors.subTextColor))
                                  : null,
                              trailing: isManager
                                  ? IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () => branchesProv.deleteBranch(branch.id),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}