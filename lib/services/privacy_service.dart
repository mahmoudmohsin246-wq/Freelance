// Privacy service helper to enforce private profile access control

import 'package:your_app/models/user.dart';

class PrivacyService {
  final RelationshipService? relationshipService;
  final AdminService? adminService;

  PrivacyService({this.relationshipService, this.adminService});

  /// Return true if requester can view target's full profile.
  Future<bool> canViewProfile({User? requester, required User target}) async {
    final bool isPrivate = (target.profile != null && target.profile['isPrivateProfile'] == true)
        || (target.isPrivateProfile == true);

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
