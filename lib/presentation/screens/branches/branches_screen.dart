import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/branch_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../common_widgets/empty_state_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final academyId = Provider.of<WorkspaceProvider>(context, listen: false).selectedAcademy?.id;
      if (academyId != null) {
        Provider.of<BranchProvider>(context, listen: false).fetchBranches(academyId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final branchProvider = Provider.of<BranchProvider>(context);
    final workspaceProvider = Provider.of<WorkspaceProvider>(context);
    final loc = AppLocalizations.of(context);
    final academy = workspaceProvider.selectedAcademy;

    if (academy == null) {
      return const Center(child: Text('Please select an academy workspace.'));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('branchesAndGroups'),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage facility branches for ${academy.name}',
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddBranchModal(context, academy.id),
                  icon: const Icon(Icons.add_business),
                  label: Text(loc.translate('addBranch')),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: branchProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : branchProvider.branches.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.storefront_outlined,
                          title: loc.translate('noBranchesYet'),
                          description: 'Start by creating your first academy branch location.',
                          actionLabel: loc.translate('addBranch'),
                          onAction: () => _showAddBranchModal(context, academy.id),
                        )
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 400,
                            mainAxisExtent: 280,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: branchProvider.branches.length,
                          itemBuilder: (context, index) {
                            final branch = branchProvider.branches[index];
                            return Card(
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      Image.network(
                                        branch.imageUrl,
                                        height: 140,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Container(
                                          height: 140,
                                          color: AppColors.primary.withOpacity(0.2),
                                          child: const Center(
                                            child: Icon(Icons.business, size: 48, color: AppColors.primary),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.white),
                                          style: IconButton.styleFrom(backgroundColor: Colors.black45),
                                          onPressed: () => branchProvider.deleteBranch(branch.id),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          branch.name,
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                branch.address,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.phone_outlined, size: 16, color: AppColors.primary),
                                            const SizedBox(width: 6),
                                            Text(
                                              branch.phone,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Theme.of(context).textTheme.bodySmall?.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBranchModal(BuildContext context, String academyId) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final imageCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).translate('addBranch'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Branch Name', prefixIcon: Icon(Icons.business)),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on)),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: imageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Branch Photo URL',
                    hintText: 'https://...',
                    prefixIcon: Icon(Icons.image),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        await Provider.of<BranchProvider>(context, listen: false).addBranch(
                          academyId: academyId,
                          name: nameCtrl.text,
                          address: addressCtrl.text,
                          phone: phoneCtrl.text,
                          imageUrl: imageCtrl.text,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Save Branch'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
