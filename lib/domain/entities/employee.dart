class EmployeeEntity {
  final String id;
  final String academyId;
  final String name;
  final String role; // Head Coach, Trainer, Administrator, Manager, Receptionist
  final String phone;
  final double baseSalary;
  final DateTime joinedDate;

  EmployeeEntity({
    required this.id,
    required this.academyId,
    required this.name,
    required this.role,
    required this.phone,
    required this.baseSalary,
    required this.joinedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'academyId': academyId,
      'name': name,
      'role': role,
      'phone': phone,
      'baseSalary': baseSalary,
      'joinedDate': joinedDate.toIso8601String(),
    };
  }

  factory EmployeeEntity.fromMap(Map<String, dynamic> map) {
    return EmployeeEntity(
      id: map['id'] ?? '',
      academyId: map['academyId'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      phone: map['phone'] ?? '',
      baseSalary: (map['baseSalary'] ?? 0.0).toDouble(),
      joinedDate: map['joinedDate'] != null ? DateTime.parse(map['joinedDate']) : DateTime.now(),
    );
  }
}
