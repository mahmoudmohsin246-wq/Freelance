class SalaryRecordEntity {
  final String id;
  final String academyId;
  final String employeeId;
  final String employeeName;
  final double amount;
  final DateTime paymentDate;
  final String monthYear; // e.g. "August 2026"
  final String status; // Paid, Pending
  final String paymentMethod; // Bank Transfer, Cash, Cheque

  SalaryRecordEntity({
    required this.id,
    required this.academyId,
    required this.employeeId,
    required this.employeeName,
    required this.amount,
    required this.paymentDate,
    required this.monthYear,
    required this.status,
    required this.paymentMethod,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'academyId': academyId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'monthYear': monthYear,
      'status': status,
      'paymentMethod': paymentMethod,
    };
  }

  factory SalaryRecordEntity.fromMap(Map<String, dynamic> map) {
    return SalaryRecordEntity(
      id: map['id'] ?? '',
      academyId: map['academyId'] ?? '',
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      paymentDate: map['paymentDate'] != null ? DateTime.parse(map['paymentDate']) : DateTime.now(),
      monthYear: map['monthYear'] ?? '',
      status: map['status'] ?? 'Paid',
      paymentMethod: map['paymentMethod'] ?? 'Bank Transfer',
    );
  }
}
