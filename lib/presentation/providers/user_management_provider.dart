import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_management_repository.dart';

class UserManagementProvider extends ChangeNotifier {
  final UserManagementRepository _userRepo;

  List<UserEntity> _users = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;

  UserManagementProvider({required UserManagementRepository userRepo}) : _userRepo = userRepo;

  List<UserEntity> get users {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((u) {
      return u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.phone.contains(_searchQuery);
    }).toList();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchUsers(String academyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _users = await _userRepo.getUsersForAcademy(academyId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserRole(String userId, UserRole newRole) async {
    try {
      final updated = await _userRepo.updateUserRole(userId, newRole);
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeUser(String userId, String academyId) async {
    try {
      await _userRepo.removeUserFromAcademy(userId, academyId);
      _users.removeWhere((u) => u.id == userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
