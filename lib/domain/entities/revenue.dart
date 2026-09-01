class RevenueEntity {
  final String id;
  final String academyId;
  final String title;
  final double collectedAmount;
  final double remainingAmount;
  final String category; // Sponsor, Merchandise, Tournament Fee, Facility Rental
  final DateTime date;
  final String description;

  RevenueEntity({
    required this.id,
    required this.academyId,
    required this.title,
    required this.collectedAmount,
    required this.remainingAmount,
    required this.category,
    required this.date,
    required this.description,
  });

  double get totalAmount => collectedAmount + remainingAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'academyId': academyId,
      'title': title,
      'collectedAmount': collectedAmount,
      'remainingAmount': remainingAmount,
      'category': category,
      'date': date.toIso8601String(),
      'description': description,
    };
  }

  factory RevenueEntity.fromMap(Map<String, dynamic> map) {
    return RevenueEntity(
      id: map['id'] ?? '',
      academyId: map['academyId'] ?? '',
      title: map['title'] ?? '',
      collectedAmount: (map['collectedAmount'] ?? 0.0).toDouble(),
      remainingAmount: (map['remainingAmount'] ?? 0.0).toDouble(),
      category: map['category'] ?? 'Other',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      description: map['description'] ?? '',
    );
  }
}
