import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/employee_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../common_widgets/role_guard.dart';
import '../../common_widgets/empty_state_widget.dart';
import '../../../domain/entities/attendance.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final academyId = Provider.of<WorkspaceProvider>(context, listen: false).selectedAcademy?.id;
      if (academyId != null) {
        Provider.of<EmployeeProvider>(context, listen: false).fetchEmployeeData(academyId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final empProvider = Provider.of<EmployeeProvider>(context);
    final workspaceProvider = Provider.of<WorkspaceProvider>(context);
    final loc = AppLocalizations.of(context);
    final academy = workspaceProvider.selectedAcademy;

    return RoleGuard(
      child: Scaffold(
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
                        loc.translate('employeeAttendanceAndSalaries'),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'HR Payroll & Daily Attendance Tracking for ${academy?.name ?? 'Academy'}',
                        style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                      ),
                    ],
                  ),
                  if (academy != null)
                    ElevatedButton.icon(
                      onPressed: () => _showAddEmployeeModal(context, academy.id),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add Staff Member'),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  tabs: [
                    Tab(icon: const Icon(Icons.check_circle_outline), text: loc.translate('attendance')),
                    Tab(icon: const Icon(Icons.payments_outlined), text: loc.translate('salaries')),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: empProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : empProvider.employees.isEmpty
                        ? EmptyStateWidget(
                            icon: Icons.badge_outlined,
                            title: loc.translate('noEmployees'),
                            description: 'Add staff members, coaches, and trainers to start tracking attendance and payroll.',
                            actionLabel: 'Add Staff Member',
                            onAction: () => _showAddEmployeeModal(context, academy!.id),
                          )
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildAttendanceTab(context, empProvider, academy!.id, loc),
                              _buildSalariesTab(context, empProvider, academy.id, loc),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceTab(BuildContext context, EmployeeProvider empProvider, String academyId, AppLocalizations loc) {
    final formattedDate = DateFormat('EEEE, MMMM dd, yyyy').format(empProvider.selectedDate);

    return Column(
      children: [
        // Date Selector Bar
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      formattedDate,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: empProvider.selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      empProvider.setAttendanceDate(academyId, picked);
                    }
                  },
                  icon: const Icon(Icons.edit_calendar, size: 18),
                  label: const Text('Change Date'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        Expanded(
          child: Card(
            child: ListView.separated(
              itemCount: empProvider.employees.length,
              separatorBuilder: (c, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final emp = empProvider.employees[index];
                final att = empProvider.todayAttendance.firstWhere(
                  (a) => a.employeeId == emp.id,
                  orElse: () => AttendanceEntity(
                    id: '',
                    academyId: academyId,
                    employeeId: emp.id,
                    date: empProvider.selectedDate,
                    status: AttendanceStatus.present,
                    notes: '',
                  ),
                );

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(emp.name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                  title: Text(emp.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${emp.role} • ${emp.phone}'),
                  trailing: SegmentedButton<AttendanceStatus>(
                    segments: [
                      ButtonSegment(value: AttendanceStatus.present, label: Text(loc.translate('present'))),
                      ButtonSegment(value: AttendanceStatus.absent, label: Text(loc.translate('absent'))),
                      ButtonSegment(value: AttendanceStatus.late, label: Text(loc.translate('late'))),
                      ButtonSegment(value: AttendanceStatus.leave, label: Text(loc.translate('leave'))),
                    ],
                    selected: {att.status},
                    onSelectionChanged: (Set<AttendanceStatus> newSelection) {
                      empProvider.updateAttendance(
                        academyId: academyId,
                        employeeId: emp.id,
                        status: newSelection.first,
                        notes: att.notes,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalariesTab(BuildContext context, EmployeeProvider empProvider, String academyId, AppLocalizations loc) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Salary Payout Records',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () => _showRecordSalaryModal(context, empProvider, academyId),
              icon: const Icon(Icons.payment),
              label: const Text('Record Salary Payout'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Card(
            child: ListView.separated(
              itemCount: empProvider.salaryRecords.length,
              separatorBuilder: (c, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final sal = empProvider.salaryRecords[index];
                final formattedDate = DateFormat('MMM dd, yyyy').format(sal.paymentDate);

                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.accent,
                    child: Icon(Icons.attach_money, color: Colors.white, size: 20),
                  ),
                  title: Text(sal.employeeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Period: ${sal.monthYear} • Method: ${sal.paymentMethod} • Date: $formattedDate'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '-\$${sal.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          sal.status,
                          style: const TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showAddEmployeeModal(BuildContext context, String academyId) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController(text: 'Head Coach');
    final phoneCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();

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
                const Text('Add Staff Member', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Divider(),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Employee Name', prefixIcon: Icon(Icons.person)),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: roleCtrl,
                  decoration: const InputDecoration(labelText: 'Job Title / Role', prefixIcon: Icon(Icons.badge)),
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
                  controller: salaryCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Base Monthly Salary (\$)', prefixIcon: Icon(Icons.attach_money)),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        await Provider.of<EmployeeProvider>(context, listen: false).addEmployee(
                          academyId: academyId,
                          name: nameCtrl.text,
                          role: roleCtrl.text,
                          phone: phoneCtrl.text,
                          baseSalary: double.tryParse(salaryCtrl.text) ?? 2000.0,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Save Employee'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRecordSalaryModal(BuildContext context, EmployeeProvider empProvider, String academyId) {
    if (empProvider.employees.isEmpty) return;

    final formKey = GlobalKey<FormState>();
    var selectedEmployee = empProvider.employees.first;
    final amountCtrl = TextEditingController(text: selectedEmployee.baseSalary.toStringAsFixed(0));
    final periodCtrl = TextEditingController(text: 'August 2026');
    final methodCtrl = TextEditingController(text: 'Direct Deposit');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
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
                  const Text('Record Salary Payout', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(),
                  const SizedBox(height: 12),
                  DropdownButtonFormField(
                    value: selectedEmployee,
                    decoration: const InputDecoration(labelText: 'Employee', prefixIcon: Icon(Icons.person)),
                    items: empProvider.employees
                        .map((e) => DropdownMenuItem(value: e, child: Text('${e.name} (${e.role})')))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedEmployee = val;
                          amountCtrl.text = val.baseSalary.toStringAsFixed(0);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount Paid (\$)', prefixIcon: Icon(Icons.attach_money)),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: periodCtrl,
                    decoration: const InputDecoration(labelText: 'Period / Month', prefixIcon: Icon(Icons.calendar_today)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: methodCtrl,
                    decoration: const InputDecoration(labelText: 'Payment Method', prefixIcon: Icon(Icons.credit_card)),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          await empProvider.recordSalaryPayout(
                            academyId: academyId,
                            employeeId: selectedEmployee.id,
                            employeeName: selectedEmployee.name,
                            amount: double.tryParse(amountCtrl.text) ?? selectedEmployee.baseSalary,
                            monthYear: periodCtrl.text,
                            paymentMethod: methodCtrl.text,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                      child: const Text('Save Payout Record'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
