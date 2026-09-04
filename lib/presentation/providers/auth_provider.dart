import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/utils/attendance_code_generator.dart';
import '../../core/services/supabase_storage_service.dart';

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
      return UserModel.fromJson(data, emailVerified: _auth.currentUser?.emailVerified ?? false);
    } on FirebaseException catch (e) {
      // A permission-denied here (for someone other than the signed-in
      // user's own uid) means the target has set their profile to
      // private and security rules are blocking the read — treat that
      // the same as "not available" rather than crashing the caller.
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
        .collection(_usersCollection)
        .where('academyName', isEqualTo: academyName)
        .get();
    _academyMembers = query.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return UserModel.fromJson(data);
    }).toList();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      _errorMessage = 'enterValidEmail';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final uid = credential.user!.uid;
      final profile = await _fetchProfile(uid);
      if (profile == null) {
        _errorMessage = 'noAccountWithEmail';
        await _auth.signOut();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = profile;
      _isAuthenticated = true;
      await _loadAcademyMembers(profile.academyName);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _mapAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
    String name,
    String email,
    String password, {
    String phone = '',
    String academyName = '',
    String nationalId = '',
    XFile? avatarFile,
    String roleChoice = 'coach',
    String managerCode = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final normalizedEmail = email.trim().toLowerCase();

    if (name.trim().isEmpty) {
      _errorMessage = 'enterName';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      _errorMessage = 'enterValidEmail';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (password.length < 6) {
      _errorMessage = 'passwordMinLength';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    UserRole role = UserRole.coach;
    if (roleChoice == 'manager') {
      if (managerCode.trim().isEmpty) {
        _errorMessage = 'managerCodeRequired';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      if (managerCode.trim() != _managerAccessCode) {
        _errorMessage = 'invalidManagerCode';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      role = UserRole.admin;
    } else if (roleChoice == 'employee') {
      role = UserRole.employee;
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(name.trim());

      // If a manager invited this email with a specific role, that takes
      // priority over whatever role the person picked themselves at
      // signup. This has to happen here (after the account exists, so
      // `request.auth` is set) rather than before registration, because an
      // unauthenticated visitor isn't allowed to read the invitations
      // collection — only a signed-in user reading their own invite is.
      try {
        final inviteDoc = await _firestore.collection('invitations').doc(normalizedEmail).get();
        final invitedRole = inviteDoc.data()?['role'] as String?;
        if (invitedRole == 'manager') {
          role = UserRole.admin;
        } else if (invitedRole == 'employee') {
          role = UserRole.employee;
        } else if (invitedRole == 'coach') {
          role = UserRole.coach;
        }
        if (inviteDoc.exists) {
          await inviteDoc.reference.delete();
        }
      } catch (e) {
        debugPrint('Error checking invitation: $e');
      }

      String avatarUrl = '';

      if (avatarFile != null) {
        try {
          final bytes = await avatarFile.readAsBytes();
          if (bytes.isNotEmpty) {
            avatarUrl = await SupabaseStorageService.uploadAvatar(user.uid, bytes);
          }
        } catch (e) {
          debugPrint('Error uploading avatar during registration: $e');
        }
      }

      final publicUserId = await AttendanceCodeGenerator.generateUniquePublicUserId(_firestore);
      final attendanceCode = await AttendanceCodeGenerator.generateUniqueAttendanceCode(_firestore);

      final profileData = {
        'name': name.trim(),
        'email': normalizedEmail,
        'role': role.name,
        'phone': phone.trim(),
        'academyName': academyName.trim(),
        'nationalId': nationalId.trim(),
        'sport': 'sportFootball',
        'avatarPath': avatarUrl,
        'publicUserId': publicUserId,
        'attendanceCode': attendanceCode,
        'isProfilePublic': true,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _firestore.collection(_usersCollection).doc(user.uid).set(profileData);

      try {
        await user.sendEmailVerification();
      } catch (e) {
        debugPrint('Error sending verification email during registration: $e');
        _errorMessage = _mapAuthError(e);
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = UserModel.fromJson(
        {...profileData, 'id': user.uid},
        emailVerified: user.emailVerified,
      );
      _isAuthenticated = true;
      await _loadAcademyMembers(academyName.trim());

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Registration failed: $e');
      _errorMessage = _mapAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      _errorMessage = 'enterValidEmail';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      await _auth.sendPasswordResetEmail(email: normalizedEmail);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      _errorMessage = _mapAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = 'noAccountWithEmail';
      notifyListeners();
      return false;
    }
    try {
      await user.sendEmailVerification();
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error resending verification email: $e');
      _errorMessage = _mapAuthError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.reload();
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(emailVerified: _auth.currentUser?.emailVerified ?? false);
    }
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? academyName,
    String? sport,
    String? avatarPath,
    String? nationalId,
  }) async {
    if (_currentUser == null) return;

    const enforcedSport = 'sportFootball';

    _currentUser = _currentUser!.copyWith(
      name: name,
      phone: phone,
      academyName: academyName,
      sport: enforcedSport,
      avatarPath: avatarPath,
      nationalId: nationalId,
    );

    final updateData = <String, dynamic>{};
    if (name != null) updateData['name'] = name;
    if (phone != null) updateData['phone'] = phone;
    if (academyName != null) updateData['academyName'] = academyName;
    if (nationalId != null) updateData['nationalId'] = nationalId;
    updateData['sport'] = enforcedSport;
    if (avatarPath != null) updateData['avatarPath'] = avatarPath;

    if (updateData.isNotEmpty) {
      await _firestore.collection(_usersCollection).doc(_currentUser!.id).update(updateData);
      if (name != null) {
        await _auth.currentUser?.updateDisplayName(name);
      }
    }

    await _loadAcademyMembers(_currentUser!.academyName);
    notifyListeners();
  }

  /// Lets a trainee/player toggle whether other players can see their
  /// profile (contact info + attendance) in the players list. Has no
  /// effect on what a manager or employee can see — they always have
  /// full access regardless of this setting.
  Future<bool> updateProfileVisibility(bool isPublic) async {
    if (_currentUser == null) return false;

    final previous = _currentUser!.isProfilePublic;
    _currentUser = _currentUser!.copyWith(isProfilePublic: isPublic);
    notifyListeners();

    try {
      await _firestore
          .collection(_usersCollection)
          .doc(_currentUser!.id)
          .update({'isProfilePublic': isPublic});

      final idx = _academyMembers.indexWhere((m) => m.id == _currentUser!.id);
      if (idx != -1) {
        _academyMembers[idx] = _academyMembers[idx].copyWith(isProfilePublic: isPublic);
      }
      return true;
    } catch (e) {
      debugPrint('Error updating profile visibility: $e');
      // Roll back the optimistic local update since the write failed.
      _currentUser = _currentUser!.copyWith(isProfilePublic: previous);
      notifyListeners();
      return false;
    }
  }

  List<UserModel> _allUsers = [];
  bool _isLoadingAllUsers = false;
  List<UserModel> get allUsers => _allUsers;
  bool get isLoadingAllUsers => _isLoadingAllUsers;

  Future<void> fetchAllUsers() async {
    _isLoadingAllUsers = true;
    notifyListeners();
    try {
      final snap = await _firestore.collection(_usersCollection).get();
      _allUsers = snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return UserModel.fromJson(data);
      }).toList();
      _allUsers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } catch (e) {
      debugPrint('Error fetching all users: $e');
    } finally {
      _isLoadingAllUsers = false;
      notifyListeners();
    }
  }

  Future<bool> updateUserRole({required String userId, required UserRole newRole}) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({'role': newRole.name});
      return true;
    } catch (e) {
      debugPrint('Error updating user role: $e');
      _errorMessage = _mapAuthError(e);
      notifyListeners();
      return false;
    }
  }

  bool _isUploadingAvatar = false;
  bool get isUploadingAvatar => _isUploadingAvatar;

  Future<bool> uploadAvatar(ImageSource source) async {
    if (_currentUser == null) return false;
    _isUploadingAvatar = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        _isUploadingAvatar = false;
        notifyListeners();
        return false;
      }

      final bytes = await pickedFile.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('imagePickerEmptyFile');
      }

      final uid = _currentUser!.id;
      final downloadUrl = await SupabaseStorageService.uploadAvatar(uid, bytes);

      await updateProfile(avatarPath: downloadUrl);

      _isUploadingAvatar = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      final msg = e.toString();
      if (msg.contains('Bucket not found') || msg.contains('bucket')) {
        _errorMessage = 'avatarUploadCorsError';
      } else if (msg.contains('unauthorized') || msg.contains('permission') || msg.contains('403')) {
        _errorMessage = 'avatarUploadPermissionError';
      } else {
        _errorMessage = 'avatarUploadGenericError';
      }
      _isUploadingAvatar = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || _currentUser == null) return false;

    if (newPassword.length < 6) {
      _errorMessage = 'passwordMinLength';
      notifyListeners();
      return false;
    }

    try {
      final cred = fb.EmailAuthProvider.credential(
        email: _currentUser!.email,
        password: oldPassword,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      if (e is fb.FirebaseAuthException &&
          (e.code == 'wrong-password' || e.code == 'invalid-credential')) {
        _errorMessage = 'incorrectCurrentPassword';
      } else {
        _errorMessage = _mapAuthError(e);
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> switchAccount(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _auth.signOut();
    final ok = await login(email, password);
    if (!ok) {
      _isLoading = false;
      notifyListeners();
    }
    return ok;
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    _isAuthenticated = false;
    _academyMembers = [];
    notifyListeners();
  }

  Future<bool> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null || _currentUser == null) return false;

    try {
      if (password != null && password.isNotEmpty) {
        final cred = fb.EmailAuthProvider.credential(
          email: _currentUser!.email,
          password: password,
        );
        await user.reauthenticateWithCredential(cred);
      }
      await _firestore.collection(_usersCollection).doc(user.uid).delete();
      await user.delete();

      _currentUser = null;
      _isAuthenticated = false;
      _academyMembers = [];
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _mapAuthError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> tryAutoLogin() async {
    final user = _auth.currentUser;
    if (user == null) {
      _isCheckingSession = false;
      notifyListeners();
      return;
    }

    final profile = await _fetchProfile(user.uid);
    if (profile == null) {
      await _auth.signOut();
      _isCheckingSession = false;
      notifyListeners();
      return;
    }

    _currentUser = profile;
    _isAuthenticated = true;
    _isCheckingSession = false;
    await _loadAcademyMembers(profile.academyName);
    notifyListeners();
  }
}