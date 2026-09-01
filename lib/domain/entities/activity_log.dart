class ActivityLogEntity {
  final String id;
  final String academyId;
  final String userId;
  final String userName;
  final String action; // Action description, e.g. "Player added", "Revenue recorded"
  final String entityType; // Player, Branch, User, Subscription, Attendance, Salary, Expense
  final String details;
  final DateTime timestamp;

  ActivityLogEntity({
    required this.id,
    required this.academyId,
    required this.userId,
    required this.userName,
    required this.action,
    required this.entityType,
    required this.details,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'academyId': academyId,
      'userId': userId,
      'userName': userName,
      'action': action,
      'entityType': entityType,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ActivityLogEntity.fromMap(Map<String, dynamic> map) {
    return ActivityLogEntity(
      id: map['id'] ?? '',
      academyId: map['academyId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      action: map['action'] ?? '',
      entityType: map['entityType'] ?? '',
      details: map['details'] ?? '',
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']) : DateTime.now(),
    );
  }
}
