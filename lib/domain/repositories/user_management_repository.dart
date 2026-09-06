import '../entities/user.dart';

abstract class UserManagementRepository {
  Future<List<UserEntity>> getUsersForAcademy(String academyId);
  Future<UserEntity> updateUserRole(String userId, UserRole role);
  Future<void> removeUserFromAcademy(String userId, String academyId);
}