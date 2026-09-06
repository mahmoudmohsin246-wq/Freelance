import '../entities/revenue.dart';
import '../entities/expense.dart';

abstract class FinancialRepository {

  Future<List<RevenueEntity>> getRevenues(String academyId);
  Future<RevenueEntity> addRevenue(RevenueEntity revenue);


  Future<List<ExpenseEntity>> getExpenses(String academyId);
  Future<ExpenseEntity> addExpense(ExpenseEntity expense);
}