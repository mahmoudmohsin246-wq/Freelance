import 'package:flutter/material.dart';
import '../../domain/entities/branch.dart';
import '../../domain/repositories/branch_repository.dart';

class BranchProvider extends ChangeNotifier {
  final BranchRepository _branchRepo;

  List<BranchEntity> _branches = [];
  bool _isLoading = false;
  String? _error;

  BranchProvider({required BranchRepository branchRepo}) : _branchRepo = branchRepo;

  List<BranchEntity> get branches => _branches;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchBranches(String academyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _branches = await _branchRepo.getBranchesForAcademy(academyId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addBranch({
    required String academyId,
    required String name,
    required String address,
    required String phone,
    required String imageUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newBranch = BranchEntity(
        id: 'branch-${DateTime.now().millisecondsSinceEpoch}',
        academyId: academyId,
        name: name,
        address: address,
        phone: phone,
        imageUrl: imageUrl.isNotEmpty
            ? imageUrl
            : 'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=500',
        createdAt: DateTime.now(),
      );

      final added = await _branchRepo.addBranch(newBranch);
      _branches.add(added);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteBranch(String id) async {
    try {
      await _branchRepo.deleteBranch(id);
      _branches.removeWhere((b) => b.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
