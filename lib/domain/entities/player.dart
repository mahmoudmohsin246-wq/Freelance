class PlayerEntity {
  final String id;
  final String academyId;
  final String branchId;
  final String name;
  final int age;
  final String phone;
  final String sport;
  final String status; // Active, Inactive, Pending
  final DateTime joinedDate;
  final String notes;

  PlayerEntity({
    required this.id,
    required this.academyId,
    required this.branchId,
    required this.name,
    required this.age,
    required this.phone,
    required this.sport,
    required this.status,
    required this.joinedDate,
    required this.notes,
  });

  PlayerEntity copyWith({
    String? id,
    String? academyId,
    String? branchId,
    String? name,
    int? age,
    String? phone,
    String? sport,
    String? status,
    DateTime? joinedDate,
    String? notes,
  }) {
    return PlayerEntity(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      branchId: branchId ?? this.branchId,
      name: name ?? this.name,
      age: age ?? this.age,
      phone: phone ?? this.phone,
      sport: sport ?? this.sport,
      status: status ?? this.status,
      joinedDate: joinedDate ?? this.joinedDate,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'academyId': academyId,
      'branchId': branchId,
      'name': name,
      'age': age,
      'phone': phone,
      'sport': sport,
      'status': status,
      'joinedDate': joinedDate.toIso8601String(),
      'notes': notes,
    };
  }

  factory PlayerEntity.fromMap(Map<String, dynamic> map) {
    return PlayerEntity(
      id: map['id'] ?? '',
      academyId: map['academyId'] ?? '',
      branchId: map['branchId'] ?? '',
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      phone: map['phone'] ?? '',
      sport: map['sport'] ?? '',
      status: map['status'] ?? 'Active',
      joinedDate: map['joinedDate'] != null ? DateTime.parse(map['joinedDate']) : DateTime.now(),
      notes: map['notes'] ?? '',
    );
  }
}
