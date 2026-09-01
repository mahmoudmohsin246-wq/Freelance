import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Invitation {
  final String id;
  final String email;
  final String role;
  final DateTime createdAt;

  Invitation({
    required this.id,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Invitation.fromJson(Map<String, dynamic> json) => Invitation(
        id: json['id'],
        email: json['email'],
        role: json['role'],
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}

class InvitationsProvider extends ChangeNotifier {
  static const _storageKey = 'app_invitations';

  List<Invitation> _invitations = [];
  bool _isLoading = true;

  List<Invitation> get invitations => _invitations;
  bool get isLoading => _isLoading;

  InvitationsProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_storageKey);
      if (encoded != null) {
        final decoded = json.decode(encoded) as List<dynamic>;
        _invitations = decoded.map((e) => Invitation.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading invitations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(_invitations.map((i) => i.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> sendInvitation(String email, String role) async {
    final normalizedEmail = email.trim().toLowerCase();
    _invitations.removeWhere((i) => i.email == normalizedEmail);
    _invitations.insert(
      0,
      Invitation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: normalizedEmail,
        role: role,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
    await _save();
  }

  Future<void> cancelInvitation(String id) async {
    _invitations.removeWhere((i) => i.id == id);
    notifyListeners();
    await _save();
  }

  Invitation? findInvitationFor(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      return _invitations.firstWhere((i) => i.email == normalizedEmail);
    } catch (_) {
      return null;
    }
  }
  Future<void> consumeInvitation(String id) async {
    await cancelInvitation(id);
  }
}
