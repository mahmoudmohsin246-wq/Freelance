import '../../domain/entities/revenue.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/financial_repository.dart';
import '../datasources/mock_database.dart';

class MockFinancialRepository implements FinancialRepository {
  final MockDatabase _db = MockDatabase.instance;

  @override
  Future<List<RevenueEntity>> getRevenues(String academyId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final list = _db.revenues.where((r) => r.academyId == academyId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<RevenueEntity> addRevenue(RevenueEntity revenue) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _db.revenues.insert(0, revenue);
    return revenue;
  }

  @override
  Future<List<ExpenseEntity>> getExpenses(String academyId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final list = _db.expenses.where((e) => e.academyId == academyId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<ExpenseEntity> addExpense(ExpenseEntity expense) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _db.expenses.insert(0, expense);
    return expense;
  }
}
