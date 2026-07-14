class GymModel {
  final int id;
  final String name;
  final int? ownerId;
  final String? ownerName;
  final String? ownerUsername;
  final String? logoUrl;
  final String primaryColor; // Hex string e.g. '#DC2626'
  final String secondaryColor; // Hex string e.g. '#EF4444'
  final bool isSetupComplete;
  final bool isActive;
  final int branchCount;
  final int customerCount;
  final int staffCount;
  final DateTime? createdAt;

  GymModel({
    required this.id,
    required this.name,
    this.ownerId,
    this.ownerName,
    this.ownerUsername,
    this.logoUrl,
    this.primaryColor = '#DC2626',
    this.secondaryColor = '#EF4444',
    this.isSetupComplete = false,
    this.isActive = true,
    this.branchCount = 0,
    this.customerCount = 0,
    this.staffCount = 0,
    this.createdAt,
  });

  factory GymModel.fromJson(Map<String, dynamic> json) {
    return GymModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      ownerId: json['owner_id'] ?? json['ownerId'],
      ownerName: json['owner_name'] ?? json['ownerName'],
      ownerUsername: json['owner_username'] ?? json['ownerUsername'],
      logoUrl: json['logo_url'] ?? json['logoUrl'],
      primaryColor: json['primary_color'] ?? json['primaryColor'] ?? '#DC2626',
      secondaryColor: json['secondary_color'] ?? json['secondaryColor'] ?? '#EF4444',
      isSetupComplete: json['is_setup_complete'] ?? json['isSetupComplete'] ?? false,
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      branchCount: json['branch_count'] ?? json['branchCount'] ?? 0,
      customerCount: json['customer_count'] ?? json['customerCount'] ?? 0,
      staffCount: json['staff_count'] ?? json['staffCount'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'owner_username': ownerUsername,
      'logo_url': logoUrl,
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'is_setup_complete': isSetupComplete,
      'is_active': isActive,
      'branch_count': branchCount,
      'customer_count': customerCount,
      'staff_count': staffCount,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  GymModel copyWith({
    int? id,
    String? name,
    int? ownerId,
    String? ownerName,
    String? ownerUsername,
    String? logoUrl,
    String? primaryColor,
    String? secondaryColor,
    bool? isSetupComplete,
    bool? isActive,
    int? branchCount,
    int? customerCount,
    int? staffCount,
    DateTime? createdAt,
  }) {
    return GymModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerUsername: ownerUsername ?? this.ownerUsername,
      logoUrl: logoUrl ?? this.logoUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      isSetupComplete: isSetupComplete ?? this.isSetupComplete,
      isActive: isActive ?? this.isActive,
      branchCount: branchCount ?? this.branchCount,
      customerCount: customerCount ?? this.customerCount,
      staffCount: staffCount ?? this.staffCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get the email domain derived from the gym name.
  /// e.g. "Body Art" → "bodyart.com"
  String get emailDomain {
    final sanitized = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    return '$sanitized.com';
  }
}
