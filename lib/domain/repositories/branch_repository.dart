import '../entities/branch.dart';

abstract class BranchRepository {
  Future<List<BranchEntity>> getBranchesForAcademy(String academyId);
  Future<BranchEntity> addBranch(BranchEntity branch);
  Future<BranchEntity> updateBranch(BranchEntity branch);
  Future<void> deleteBranch(String id);
}
