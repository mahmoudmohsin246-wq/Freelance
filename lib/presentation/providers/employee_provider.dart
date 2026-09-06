import 'package:flutter/material.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/entities/salary.dart';
import '../../domain/repositories/employee_repository.dart';

class EmployeeProvider extends ChangeNotifier {
  final EmployeeRepository _employeeRepo;

  List<EmployeeEntity> _employees = [];
  List<AttendanceEntity> _todayAttendance = [];
  List<SalaryRecordEntity> _salaryRecords = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _error;

  EmployeeProvider({required EmployeeRepository employeeRepo}) : _employeeRepo = employeeRepo;

  List<EmployeeEntity> get employees => _employees;
  List<AttendanceEntity> get todayAttendance => _todayAttendance;
  List<SalaryRecordEntity> get salaryRecords => _salaryRecords;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchEmployeeData(String academyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _employees = await _employeeRepo.getEmployees(academyId);
      _todayAttendance = await _employeeRepo.getAttendanceForDate(academyId, _selectedDate);
      _salaryRecords = await _employeeRepo.getSalaryRecords(academyId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setAttendanceDate(String academyId, DateTime date) async {
    _selectedDate = date;
    _todayAttendance = await _employeeRepo.getAttendanceForDate(academyId, date);
    notifyListeners();
  }

  Future<void> updateAttendance({
    required String academyId,
    required String employeeId,
    required AttendanceStatus status,
    required String notes,
  }) async {
    final record = AttendanceEntity(
      id: 'att-${DateTime.now().millisecondsSinceEpoch}',
      academyId: academyId,
      employeeId: employeeId,
      date: _selectedDate,
      status: status,
      notes: notes,
    );

    await _employeeRepo.recordAttendance(record);
    _todayAttendance = await _employeeRepo.getAttendanceForDate(academyId, _selectedDate);
    notifyListeners();
  }

  Future<void> addEmployee({
    required String academyId,
    required String name,
    required String role,
    required String phone,
    required double baseSalary,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newEmp = EmployeeEntity(
        id: 'emp-${DateTime.now().millisecondsSinceEpoch}',
        academyId: academyId,
        name: name,
        role: role,
        phone: phone,
        baseSalary: baseSalary,
        joinedDate: DateTime.now(),
      );

      final added = await _employeeRepo.addEmployee(newEmp);
      _employees.add(added);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> recordSalaryPayout({
    required String academyId,
    required String employeeId,
    required String employeeName,
    required double amount,
    required String monthYear,
    required String paymentMethod,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final salary = SalaryRecordEntity(
        id: 'sal-${DateTime.now().millisecondsSinceEpoch}',
        academyId: academyId,
        employeeId: employeeId,
        employeeName: employeeName,
        amount: amount,
        paymentDate: DateTime.now(),
        monthYear: monthYear,
        status: 'Paid',
        paymentMethod: paymentMethod,
      );

      final recorded = await _employeeRepo.recordSalaryPayout(salary);
      _salaryRecords.insert(0, recorded);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}