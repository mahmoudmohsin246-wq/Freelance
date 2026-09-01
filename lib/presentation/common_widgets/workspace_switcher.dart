import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workspace_provider.dart';
import '../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';

class WorkspaceSwitcher extends StatelessWidget {
  const WorkspaceSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final workspaceProvider = Provider.of<WorkspaceProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final loc = AppLocalizations.of(context);
    final academy = workspaceProvider.selectedAcademy;
    final user = authProvider.currentUser;

    if (academy == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Text('No Academy Selected'),
      );
    }

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showWorkspaceModal(context),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    academy.logoUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      width: 44,
                      height: 44,
                      color: AppColors.primary,
                      child: Center(
                        child: Text(
                          academy.name.isNotEmpty ? academy.name[0] : 'A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        academy.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              academy.sport,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              (user?.role == UserRole.admin)
                                  ? loc.translate('administrator')
                                  : loc.translate('normalUser'),
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.unfold_more, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showWorkspaceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _WorkspaceModalContent(),
    );
  }
}

class _WorkspaceModalContent extends StatefulWidget {
  const _WorkspaceModalContent();

  @override
  State<_WorkspaceModalContent> createState() => _WorkspaceModalContentState();
}

class _WorkspaceModalContentState extends State<_WorkspaceModalContent> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sportController = TextEditingController();
  final _logoController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _showCreateForm = false;

  @override
  Widget build(BuildContext context) {
    final workspaceProvider = Provider.of<WorkspaceProvider>(context);
    final loc = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _showCreateForm ? loc.translate('createAcademy') : loc.translate('switchWorkspace'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            if (!_showCreateForm) ...[
              const SizedBox(height: 12),
              ...workspaceProvider.academies.map((acad) {
                final isSelected = acad.id == workspaceProvider.selectedAcademy?.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                    ),
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        acad.logoUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 40,
                          height: 40,
                          color: AppColors.primary,
                          child: Center(
                            child: Text(
                              acad.name[0],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      acad.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(acad.sport),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                    onTap: () {
                      workspaceProvider.switchWorkspace(acad);
                      Navigator.pop(context);
                    },
                  ),
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _showCreateForm = true),
                  icon: const Icon(Icons.add),
                  label: Text(loc.translate('createAcademy')),
                ),
              ),
            ] else ...[
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: loc.translate('academyName'),
                        prefixIcon: const Icon(Icons.sports),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _sportController,
                      decoration: InputDecoration(
                        labelText: loc.translate('sport'),
                        prefixIcon: const Icon(Icons.sports_soccer),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _logoController,
                      decoration: const InputDecoration(
                        labelText: 'Logo Image URL',
                        hintText: 'https://...',
                        prefixIcon: Icon(Icons.image),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => setState(() => _showCreateForm = false),
                            child: Text(loc.translate('cancel')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                await workspaceProvider.createAcademy(
                                  name: _nameController.text,
                                  sport: _sportController.text,
                                  logoUrl: _logoController.text,
                                  phone: _phoneController.text,
                                  address: _addressController.text,
                                );
                                if (context.mounted) Navigator.pop(context);
                              }
                            },
                            child: Text(loc.translate('saveChanges')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
