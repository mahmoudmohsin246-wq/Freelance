








import '../presentation/providers/auth_provider.dart' show UserModel;




abstract class RelationshipService {
  Future<bool> isFriend(String requesterId, String targetId);
  Future<bool> isFollower(String requesterId, String targetId);
}




abstract class AdminService {
  bool isAdmin(String userId);
}

class PrivacyService {
  final RelationshipService? relationshipService;
  final AdminService? adminService;

  PrivacyService({this.relationshipService, this.adminService});


  Future<bool> canViewProfile({UserModel? requester, required UserModel target}) async {
    final bool isPrivate = !target.isProfilePublic;

    if (!isPrivate) return true;
    if (requester == null) return false;
    if (requester.id == target.id) return true;
    if (adminService != null && adminService!.isAdmin(requester.id)) return true;

    if (relationshipService != null) {
      final isFriend = await relationshipService!.isFriend(requester.id, target.id);
      if (isFriend) return true;

      final isFollower = await relationshipService!.isFollower(requester.id, target.id);
      if (isFollower) return true;
    }

    return false;
  }
}