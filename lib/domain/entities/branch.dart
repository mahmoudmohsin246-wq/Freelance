class BranchEntity {
  final String id;
  final String academyId;
  final String name;
  final String address;
  final String phone;
  final String imageUrl;
  final DateTime createdAt;

  BranchEntity({
    required this.id,
    required this.academyId,
    required this.name,
    required this.address,
    required this.phone,
    required this.imageUrl,
    required this.createdAt,
  });

  BranchEntity copyWith({
    String? id,
    String? academyId,
    String? name,
    String? address,
    String? phone,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return BranchEntity(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'academyId': academyId,
      'name': name,
      'address': address,
      'phone': phone,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BranchEntity.fromMap(Map<String, dynamic> map) {
    return BranchEntity(
      id: map['id'] ?? '',
      academyId: map['academyId'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }
}