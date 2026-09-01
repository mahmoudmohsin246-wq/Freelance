enum UserRole { normalUser, admin }

class UserEntity {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final UserRole role;
  final List<String> authorizedAcademyIds;
  final DateTime createdAt;

  UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.role,
    required this.authorizedAcademyIds,
    required this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    UserRole? role,
    List<String>? authorizedAcademyIds,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      authorizedAcademyIds: authorizedAcademyIds ?? this.authorizedAcademyIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'role': role.name,
      'authorizedAcademyIds': authorizedAcademyIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      role: map['role'] == 'admin' ? UserRole.admin : UserRole.normalUser,
      authorizedAcademyIds: List<String>.from(map['authorizedAcademyIds'] ?? []),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }
}
