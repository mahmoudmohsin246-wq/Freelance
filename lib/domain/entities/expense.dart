class ExpenseEntity {
  final String id;
  final String academyId;
  final String name;
  final double amount;
  final DateTime date;
  final String description;
  final String category;
  final String notes;

  ExpenseEntity({
    required this.id,
    required this.academyId,
    required this.name,
    required this.amount,
    required this.date,
    required this.description,
    required this.category,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'academyId': academyId,
      'name': name,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'category': category,
      'notes': notes,
    };
  }

  factory ExpenseEntity.fromMap(Map<String, dynamic> map) {
    return ExpenseEntity(
      id: map['id'] ?? '',
      academyId: map['academyId'] ?? '',
      name: map['name'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      description: map['description'] ?? '',
      category: map['category'] ?? 'General',
      notes: map['notes'] ?? '',
    );
  }
}