import '../../domain/entities/user.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/mock_database.dart';

class MockProfileRepository implements ProfileRepository {
  final MockDatabase _db = MockDatabase.instance;

  @override
  Future<UserEntity> getUserProfile(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _db.users.firstWhere((u) => u.id == userId, orElse: () => _db.currentUser);
  }

  @override
  Future<UserEntity> updateProfile(UserEntity user) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _db.users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _db.users[index] = user;
      if (_db.currentUser.id == user.id) {
        _db.currentUser = user;
      }
    }
    return user;
  }

  @override
  Future<bool> changePassword(String userId, String oldPassword, String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Simulated successful password change
    return true;
  }

  @override
  Future<void> deleteAccount(String userId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _db.users.removeWhere((u) => u.id == userId);
  }
}
