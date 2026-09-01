import 'package:flutter/material.dart';
import '../../domain/entities/invitation.dart';
import '../../domain/repositories/invitation_repository.dart';

class InvitationProvider extends ChangeNotifier {
  final InvitationRepository _invitationRepo;

  List<InvitationEntity> _invitations = [];
  bool _isLoading = false;
  String? _error;

  InvitationProvider({required InvitationRepository invitationRepo})
      : _invitationRepo = invitationRepo;

  List<InvitationEntity> get invitations => _invitations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchInvitations(String academyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _invitations = await _invitationRepo.getInvitationsForAcademy(academyId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendInvitation({
    required String academyId,
    required String email,
    required String role,
    required String invitedBy,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newInv = InvitationEntity(
        id: 'inv-${DateTime.now().millisecondsSinceEpoch}',
        academyId: academyId,
        email: email,
        role: role,
        status: InvitationStatus.pending,
        sentAt: DateTime.now(),
        invitedBy: invitedBy,
      );

      final sent = await _invitationRepo.sendInvitation(newInv);
      _invitations.add(sent);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelInvitation(String id) async {
    try {
      await _invitationRepo.cancelInvitation(id);
      _invitations.removeWhere((i) => i.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
