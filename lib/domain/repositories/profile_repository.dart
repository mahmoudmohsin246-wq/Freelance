import '../entities/user.dart';

abstract class ProfileRepository {
  Future<UserEntity> getUserProfile(String userId);
  Future<UserEntity> updateProfile(UserEntity user);
  Future<bool> changePassword(String userId, String oldPassword, String newPassword);
  Future<void> deleteAccount(String userId);
}
