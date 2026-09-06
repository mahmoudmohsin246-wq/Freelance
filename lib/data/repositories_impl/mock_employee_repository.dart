import '../../domain/entities/employee.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/entities/salary.dart';
import '../../domain/repositories/employee_repository.dart';
import '../datasources/mock_database.dart';

class MockEmployeeRepository implements EmployeeRepository {
  final MockDatabase _db = MockDatabase.instance;

  @override
  Future<List<EmployeeEntity>> getEmployees(String academyId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _db.employees.where((e) => e.academyId == academyId).toList();
  }

  @override
  Future<EmployeeEntity> addEmployee(EmployeeEntity employee) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _db.employees.add(employee);
    return employee;
  }

  @override
  Future<List<AttendanceEntity>> getAttendanceForDate(String academyId, DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _db.attendanceRecords.where((a) {
      return a.academyId == academyId &&
          a.date.year == date.year &&
          a.date.month == date.month &&
          a.date.day == date.day;
    }).toList();
  }

  @override
  Future<void> recordAttendance(AttendanceEntity attendance) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _db.attendanceRecords.indexWhere((a) =>
        a.academyId == attendance.academyId &&
        a.employeeId == attendance.employeeId &&
        a.date.year == attendance.date.year &&
        a.date.month == attendance.date.month &&
        a.date.day == attendance.date.day);

    if (index != -1) {
      _db.attendanceRecords[index] = attendance;
    } else {
      _db.attendanceRecords.add(attendance);
    }
  }

  @override
  Future<List<SalaryRecordEntity>> getSalaryRecords(String academyId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final records = _db.salaryRecords.where((s) => s.academyId == academyId).toList();
    records.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    return records;
  }

  @override
  Future<SalaryRecordEntity> recordSalaryPayout(SalaryRecordEntity salary) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _db.salaryRecords.insert(0, salary);
    return salary;
  }
}