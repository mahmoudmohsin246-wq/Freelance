class PackageEntity {
  final String id;
  final String title;
  final double price;
  final String billingPeriod;
  final List<String> features;
  final bool isFreeTier;

  PackageEntity({
    required this.id,
    required this.title,
    required this.price,
    required this.billingPeriod,
    required this.features,
    this.isFreeTier = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'billingPeriod': billingPeriod,
      'features': features,
      'isFreeTier': isFreeTier,
    };
  }

  factory PackageEntity.fromMap(Map<String, dynamic> map) {
    return PackageEntity(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      billingPeriod: map['billingPeriod'] ?? 'Monthly',
      features: List<String>.from(map['features'] ?? []),
      isFreeTier: map['isFreeTier'] ?? false,
    );
  }
}

class SubscriptionEntity {
  final String id;
  final String academyId;
  final String packageId;
  final String packageName;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final double pricePaid;

  SubscriptionEntity({
    required this.id,
    required this.academyId,
    required this.packageId,
    required this.packageName,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.pricePaid,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'academyId': academyId,
      'packageId': packageId,
      'packageName': packageName,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'pricePaid': pricePaid,
    };
  }

  factory SubscriptionEntity.fromMap(Map<String, dynamic> map) {
    return SubscriptionEntity(
      id: map['id'] ?? '',
      academyId: map['academyId'] ?? '',
      packageId: map['packageId'] ?? '',
      packageName: map['packageName'] ?? '',
      status: map['status'] ?? 'Active',
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : DateTime.now(),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : DateTime.now(),
      pricePaid: (map['pricePaid'] ?? 0.0).toDouble(),
    );
  }
}