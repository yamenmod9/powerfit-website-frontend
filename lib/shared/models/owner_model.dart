/// Model representing a gym owner account created by the super admin.
class OwnerModel {
  final int id;
  final String username;
  final String fullName;
  final String? email;
  final String? phone;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  OwnerModel({
    required this.id,
    required this.username,
    required this.fullName,
    this.email,
    this.phone,
    this.isActive = true,
    this.createdAt,
    this.lastLogin,
  });

  factory OwnerModel.fromJson(Map<String, dynamic> json) {
    return OwnerModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      email: json['email'],
      phone: json['phone'],
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      lastLogin: json['last_login'] != null
          ? DateTime.tryParse(json['last_login'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }
}
