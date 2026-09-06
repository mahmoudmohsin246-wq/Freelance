enum AttendanceStatus { present, absent, late, leave }

class AttendanceEntity {
  final String id;
  final String academyId;
  final String employeeId;
  final DateTime date;
  final AttendanceStatus status;
  final String notes;

  AttendanceEntity({
    required this.id,
    required this.academyId,
    required this.employeeId,
    required this.date,
    required this.status,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'academyId': academyId,
      'employeeId': employeeId,
      'date': date.toIso8601String(),
      'status': status.name,
      'notes': notes,
    };
  }

  factory AttendanceEntity.fromMap(Map<String, dynamic> map) {
    return AttendanceEntity(
      id: map['id'] ?? '',
      academyId: map['academyId'] ?? '',
      employeeId: map['employeeId'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AttendanceStatus.present,
      ),
      notes: map['notes'] ?? '',
    );
  }
}