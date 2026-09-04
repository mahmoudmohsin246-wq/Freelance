import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/utils/attendance_code_generator.dart';
import '../../core/services/supabase_storage_service.dart';
import '../../services/privacy_service.dart';

enum UserRole { admin, coach, employee }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String phone;
  final String academyName;
  final String sport;
  final String avatarPath;
  final bool emailVerified;
  final String nationalId;
  final String attendanceCode;
  final String publicUserId;
  // Only meaningful for trainee/player (coach) accounts. When false, the
  // player's contact info and attendance calendar are hidden from other
  // players in the players list — managers and employees can always see
  // them regardless of this flag. Defaults to true (normal/public) so
  // existing accounts keep their current behavior.
  final bool isProfilePublic;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
    this.academyName = '',
    this.sport = 'sportFootball',
    this.avatarPath = '',
    this.emailVerified = false,
    this.nationalId = '',
    this.attendanceCode = '',
    this.publicUserId = '',
    this.isProfilePublic = true,
  });

  UserModel copyWith({
    String? name,
    String? phone,
    String? academyName,
    String? sport,
    String? avatarPath,
    bool? emailVerified,
    String? nationalId,
    String? attendanceCode,
    String? publicUserId,
    bool? isProfilePublic,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role,
      phone: phone ?? this.phone,
      academyName: academyName ?? this.academyName,
      sport: 'sportFootball',
      avatarPath: avatarPath ?? this.avatarPath,
      emailVerified: emailVerified ?? this.emailVerified,
      nationalId: nationalId ?? this.nationalId,
      attendanceCode: attendanceCode ?? this.attendanceCode,
      publicUserId: publicUserId ?? this.publicUserId,
      isProfilePublic: isProfilePublic ?? this.isProfilePublic,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        'phone': phone,
        'academyName': academyName,
        'sport': 'sportFootball',
        'avatarPath': avatarPath,
        'nationalId': nationalId,
        'attendanceCode': attendanceCode,
        'publicUserId': publicUserId,
        'isProfilePublic': isProfilePublic,
      };

  factory UserModel.fromJson(Map<String, dynamic> json, {bool emailVerified = false}) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: UserRole.values.firstWhere(
          (e) => e.name == json['role'],
          orElse: () => UserRole.employee,
        ),
        phone: json['phone'] as String? ?? '',
        academyName: json['academyName'] as String? ?? '',
        sport: 'sportFootball',
        avatarPath: json['avatarPath'] as String? ?? '',
        emailVerified: emailVerified,
        nationalId: json['nationalId'] as String? ?? '',
        attendanceCode: json['attendanceCode'] as String? ?? '',
        publicUserId: json['publicUserId'] as String? ?? '',
        isProfilePublic: json['isProfilePublic'] as bool? ?? true,
      );
}

class AuthProvider extends ChangeNotifier {
  static const String _managerAccessCode = 'k8f09719';
  static const String _usersCollection = 'users';

  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isCheckingSession = true;
  String? _errorMessage;

  List<UserModel> _academyMembers = [];

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isCheckingSession => _isCheckingSession;
  String? get errorMessage => _errorMessage;
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  bool get isManager => _currentUser?.role == UserRole.admin;

  // "Player" in the app's UI (trainee) maps to UserRole.coach internally.
  bool get isPlayer => _currentUser?.role == UserRole.coach;

  bool get isProfilePublic => _currentUser?.isProfilePublic ?? true;

  bool get canTakeAttendance =>
      _currentUser != null &&
      (_currentUser!.role == UserRole.admin || _currentUser!.role == UserRole.employee);

  List<UserModel> get employeeAccounts {
    final staff = _academyMembers
        .where((a) => a.role == UserRole.employee || a.role == UserRole.coach)
        .toList();
    if (_currentUser != null &&
        (_currentUser!.role == UserRole.employee || _currentUser!.role == UserRole.coach)) {
      if (!staff.any((s) => s.id == _currentUser!.id)) {
        staff.add(_currentUser!);
      }
    }
    return staff;
  }

  List<UserModel> get otherAccounts {
    final currentEmail = _currentUser?.email.toLowerCase();
    return _academyMembers.where((a) => a.email.toLowerCase() != currentEmail).toList();
  }

  AuthProvider() {
    tryAutoLogin();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _mapAuthError(Object e) {
    if (e is fb.FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'enterValidEmail';
        case 'user-not-found':
          return 'noAccountWithEmail';
        case 'wrong-password':
        case 'invalid-credential':
          return 'incorrectPassword';
        case 'email-already-in-use':
          return 'emailAlreadyRegistered';
        case 'weak-password':
          return 'passwordMinLength';
        case 'too-many-requests':
          return 'tooManyRequests';
        case 'network-request-failed':
          return 'networkError';
        case 'user-disabled':
          return 'accountDisabled';
        default:
          return 'genericError';
      }
    }
    return 'genericError';
  }

  /// Fetches a single user's profile by Firebase UID. Used by managers to
  /// look up a player/trainee's contact info (email, phone, national ID)
  /// for the attendance calendar screen.
  Future<UserModel?> fetchUserById(String uid) => _fetchProfile(uid);

  /// Returns this person's short 6-digit attendance code, generating and
  /// persisting a new unique one the first time it's needed. Works for
  /// employees and any linked player/trainee account alike, since both are
  /// just `UserModel` accounts.
  Future<String> ensureAttendanceCode(UserModel user) async {
    if (user.attendanceCode.trim().isNotEmpty) return user.attendanceCode;

    final code = await AttendanceCodeGenerator.generateUniqueAttendanceCode(_firestore);
    await _firestore.collection(_usersCollection).doc(user.id).update({'attendanceCode': code});

    final idx = _academyMembers.indexWhere((m) => m.id == user.id);
    if (idx != -1) _academyMembers[idx] = _academyMembers[idx].copyWith(attendanceCode: code);
    if (_currentUser?.id == user.id) _currentUser = _currentUser!.copyWith(attendanceCode: code);
    notifyListeners();

    return code;
  }

  /// Returns this person's 6-digit Public User ID, generating a unique one if missing.
  Future<String> ensurePublicUserId(UserModel user) async {
    if (user.publicUserId.trim().isNotEmpty) return user.publicUserId;

    final code = await AttendanceCodeGenerator.generateUniquePublicUserId(_firestore);
    await _firestore.collection(_usersCollection).doc(user.id).update({'publicUserId': code});

    final idx = _academyMembers.indexWhere((m) => m.id == user.id);
    if (idx != -1) _academyMembers[idx] = _academyMembers[idx].copyWith(publicUserId: code);
    if (_currentUser?.id == user.id) _currentUser = _currentUser!.copyWith(publicUserId: code);
    notifyListeners();

    return code;
  }

  Future<UserModel?> _fetchProfile(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      data['id'] = uid;

      // If this is the signed-in Firebase user, always return full profile
      final fbUser = _auth.currentUser;
      if (fbUser != null && fbUser.uid == uid) {
        return UserModel.fromJson(data, emailVerified: fbUser.emailVerified);
      }

      // Build target for privacy checks
      final target = UserModel.fromJson({...data}, emailVerified: false);

      // Use the privacy helper (no relationship/admin services wired here)
      final privacyService = PrivacyService(relationshipService: null, adminService: null);

      // Check whether the currently loaded local _currentUser may view the target profile.
      final canView = await privacyService.canViewProfile(requester: _currentUser, target: target);

      if (!canView) {
        // Return limited public view (Option B): id + displayName + private flag
        final limited = UserModel(
          id: uid,
          name: data['name'] as String? ?? '',
          email: '',
          role: UserRole.employee, // placeholder; calling code should not rely on sensitive fields
          phone: '',
          academyName: '',
          sport: 'sportFootball',
          avatarPath: '',
          emailVerified: false,
          nationalId: '',
          attendanceCode: '',
          publicUserId: '',
          isProfilePublic: false,
        );
        return limited;
      }

      // Authorized: return full profile
      return UserModel.fromJson(data, emailVerified: fbUser?.emailVerified ?? false);
    } on FirebaseException catch (e) {
      debugPrint('Error fetching profile ($uid): ${e.code}');
      return null;
    }
  }

  Future<void> _loadAcademyMembers(String academyName) async {
    if (academyName.trim().isEmpty) {
      _academyMembers = [];
      return;
    }
    final query = await _firestore
{