import '../entities/invitation.dart';

abstract class InvitationRepository {
  Future<List<InvitationEntity>> getInvitationsForAcademy(String academyId);
  Future<InvitationEntity> sendInvitation(InvitationEntity invitation);
  Future<void> cancelInvitation(String id);
}
