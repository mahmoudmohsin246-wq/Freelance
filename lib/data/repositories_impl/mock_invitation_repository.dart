import '../../domain/entities/invitation.dart';
import '../../domain/repositories/invitation_repository.dart';
import '../datasources/mock_database.dart';

class MockInvitationRepository implements InvitationRepository {
  final MockDatabase _db = MockDatabase.instance;

  @override
  Future<List<InvitationEntity>> getInvitationsForAcademy(String academyId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _db.invitations.where((i) => i.academyId == academyId).toList();
  }

  @override
  Future<InvitationEntity> sendInvitation(InvitationEntity invitation) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _db.invitations.add(invitation);
    return invitation;
  }

  @override
  Future<void> cancelInvitation(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _db.invitations.removeWhere((i) => i.id == id);
  }
}
