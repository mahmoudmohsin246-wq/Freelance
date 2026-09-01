import '../../domain/entities/branch.dart';
import '../../domain/repositories/branch_repository.dart';
import '../datasources/mock_database.dart';

class MockBranchRepository implements BranchRepository {
  final MockDatabase _db = MockDatabase.instance;

  @override
  Future<List<BranchEntity>> getBranchesForAcademy(String academyId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _db.branches.where((b) => b.academyId == academyId).toList();
  }

  @override
  Future<BranchEntity> addBranch(BranchEntity branch) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _db.branches.add(branch);
    return branch;
  }

  @override
  Future<BranchEntity> updateBranch(BranchEntity branch) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _db.branches.indexWhere((b) => b.id == branch.id);
    if (index != -1) {
      _db.branches[index] = branch;
    }
    return branch;
  }

  @override
  Future<void> deleteBranch(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _db.branches.removeWhere((b) => b.id == id);
  }
}
