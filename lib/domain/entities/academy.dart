class AcademyEntity {
  final String id;
  final String name;
  final String sport;
  final String logoUrl;
  final String phone;
  final String address;
  final DateTime createdAt;
  final DateTime updatedAt;

  AcademyEntity({
    required this.id,
    required this.name,
    required this.sport,
    required this.logoUrl,
    required this.phone,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  AcademyEntity copyWith({
    String? id,
    String? name,
    String? sport,
    String? logoUrl,
    String? phone,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AcademyEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      sport: sport ?? this.sport,
      logoUrl: logoUrl ?? this.logoUrl,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sport': sport,
      'logoUrl': logoUrl,
      'phone': phone,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AcademyEntity.fromMap(Map<String, dynamic> map) {
    return AcademyEntity(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      sport: map['sport'] ?? '',
      logoUrl: map['logoUrl'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
    );
  }
}