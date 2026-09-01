import '../entities/revenue.dart';
import '../entities/expense.dart';

abstract class FinancialRepository {
  // Revenues
  Future<List<RevenueEntity>> getRevenues(String academyId);
  Future<RevenueEntity> addRevenue(RevenueEntity revenue);

  // Expenses
  Future<List<ExpenseEntity>> getExpenses(String academyId);
  Future<ExpenseEntity> addExpense(ExpenseEntity expense);
}
