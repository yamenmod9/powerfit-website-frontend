class ClientModel {
  final int id;
  final String fullName;
  final String? phone;
  final String? email;
  final String qrCode;
  final String subscriptionStatus;
  final String? branchName;
  final DateTime? createdAt;
  final String? preferredLanguage;

  ClientModel({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    required this.qrCode,
    required this.subscriptionStatus,
    this.branchName,
    this.createdAt,
    this.preferredLanguage,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    // Debug logging
    print('🔍 ClientModel.fromJson - Raw JSON: $json');
    
    // Determine subscription status
    String status = 'inactive';
    if (json['active_subscription'] != null && json['active_subscription'] is Map) {
      status = json['active_subscription']['status'] ?? 'active';
      print('✅ Found active_subscription: $status');
    } else if (json['subscription_status'] != null) {
      status = json['subscription_status'];
      print('✅ Found subscription_status: $status');
    } else if (json['is_active'] == true) {
      status = 'active';
      print('✅ Found is_active=true, setting status to active');
    } else {
      print('⚠️ No subscription status indicators found, defaulting to inactive');
    }

    // Generate QR code if not provided by backend
    // Format: customer_id:{id} (matches QR scanner expectations)
    final customerId = json['id'];
    String qrCodeValue = json['qr_code'] ?? 'customer_id:$customerId';
    
    // If qr_code is empty, generate it
    if (qrCodeValue.isEmpty) {
      qrCodeValue = 'customer_id:$customerId';
    }
    
    print('🔑 Generated QR Code: $qrCodeValue');
    print('📊 Final subscription status: $status');

    return ClientModel(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      phone: json['phone'],
      email: json['email'],
      qrCode: qrCodeValue,
      subscriptionStatus: status,
      branchName: json['branch_name'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      preferredLanguage: json['preferred_language'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'qr_code': qrCode,
      'subscription_status': subscriptionStatus,
      'branch_name': branchName,
      'created_at': createdAt?.toIso8601String(),
      'preferred_language': preferredLanguage,
    };
  }

  ClientModel copyWith({String? preferredLanguage}) {
    return ClientModel(
      id: id,
      fullName: fullName,
      phone: phone,
      email: email,
      qrCode: qrCode,
      subscriptionStatus: subscriptionStatus,
      branchName: branchName,
      createdAt: createdAt,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }

  bool get isActive => subscriptionStatus.toLowerCase() == 'active';
  bool get isFrozen => subscriptionStatus.toLowerCase() == 'frozen';
  bool get isStopped => subscriptionStatus.toLowerCase() == 'stopped';
}
