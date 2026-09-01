import '../../domain/entities/user.dart';
import '../../domain/repositories/user_management_repository.dart';
import '../datasources/mock_database.dart';

class MockUserManagementRepository implements UserManagementRepository {
  final MockDatabase _db = MockDatabase.instance;

  @override
  Future<List<UserEntity>> getUsersForAcademy(String academyId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _db.users.where((u) => u.authorizedAcademyIds.contains(academyId)).toList();
  }

  @override
  Future<UserEntity> updateUserRole(String userId, UserRole role) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _db.users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _db.users[index] = _db.users[index].copyWith(role: role);
      return _db.users[index];
    }
    throw Exception('User not found');
  }

  @override
  Future<void> removeUserFromAcademy(String userId, String academyId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _db.users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final updatedAcademies = List<String>.from(_db.users[index].authorizedAcademyIds)..remove(academyId);
      _db.users[index] = _db.users[index].copyWith(authorizedAcademyIds: updatedAcademies);
    }
  }
}
