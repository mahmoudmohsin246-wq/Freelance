enum InvitationStatus { pending, accepted, rejected }

class InvitationEntity {
  final String id;
  final String academyId;
  final String email;
  final String role;
  final InvitationStatus status;
  final DateTime sentAt;
  final String invitedBy;

  InvitationEntity({
    required this.id,
    required this.academyId,
    required this.email,
    required this.role,
    required this.status,
    required this.sentAt,
    required this.invitedBy,
  });

  InvitationEntity copyWith({
    String? id,
    String? academyId,
    String? email,
    String? role,
    InvitationStatus? status,
    DateTime? sentAt,
    String? invitedBy,
  }) {
    return InvitationEntity(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      invitedBy: invitedBy ?? this.invitedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'academyId': academyId,
      'email': email,
      'role': role,
      'status': status.name,
      'sentAt': sentAt.toIso8601String(),
      'invitedBy': invitedBy,
    };
  }

  factory InvitationEntity.fromMap(Map<String, dynamic> map) {
    return InvitationEntity(
      id: map['id'] ?? '',
      academyId: map['academyId'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'Normal User',
      status: InvitationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => InvitationStatus.pending,
      ),
      sentAt: map['sentAt'] != null ? DateTime.parse(map['sentAt']) : DateTime.now(),
      invitedBy: map['invitedBy'] ?? '',
    );
  }
}
