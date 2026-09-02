import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Invitation {
  final String id; // = normalized email, so re-inviting the same address just overwrites it
  final String email;
  final String role;
  final DateTime createdAt;

  Invitation({
    required this.id,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory Invitation.fromFirestore(Map<String, dynamic> json, String id) {
    final raw = json['createdAt'];
    return Invitation(
      id: id,
      email: json['email'] as String? ?? id,
      role: json['role'] as String? ?? 'coach',
      createdAt: raw is Timestamp ? raw.toDate() : DateTime.now(),
    );
  }
}

/// Manager-facing list of pending invitations. Backed by Firestore so it's
/// visible from any device — matching an invitation to a NEW registrant
/// (who isn't authenticated yet) happens separately, directly inside
/// `AuthProvider.register()`, right after their account is created; see the
/// comment there for why it can't go through this provider.
class InvitationsProvider extends ChangeNotifier {
  static const _collection = 'invitations';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Invitation> _invitations = [];
  bool _isLoading = true;

  List<Invitation> get invitations => _invitations;
  bool get isLoading => _isLoading;

  InvitationsProvider() {
    loadInvitations();
  }

  Future<void> loadInvitations() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snap = await _firestore.collection(_collection).get();
      final list = snap.docs.map((d) => Invitation.fromFirestore(d.data(), d.id)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _invitations = list;
    } catch (e) {
      debugPrint('Error loading invitations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendInvitation(String email, String role) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return;
    try {
      await _firestore.collection(_collection).doc(normalizedEmail).set({
        'email': normalizedEmail,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await loadInvitations();
    } catch (e) {
      debugPrint('Error sending invitation: $e');
    }
  }

  Future<void> cancelInvitation(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      debugPrint('Error cancelling invitation: $e');
    }
    _invitations.removeWhere((i) => i.id == id);
    notifyListeners();
  }
}
