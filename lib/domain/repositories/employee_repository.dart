import '../entities/employee.dart';
import '../entities/attendance.dart';
import '../entities/salary.dart';

abstract class EmployeeRepository {
  Future<List<EmployeeEntity>> getEmployees(String academyId);
  Future<EmployeeEntity> addEmployee(EmployeeEntity employee);


  Future<List<AttendanceEntity>> getAttendanceForDate(String academyId, DateTime date);
  Future<void> recordAttendance(AttendanceEntity attendance);


  Future<List<SalaryRecordEntity>> getSalaryRecords(String academyId);
  Future<SalaryRecordEntity> recordSalaryPayout(SalaryRecordEntity salary);
}