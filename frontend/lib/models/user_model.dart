class UserModel {
  final int id;
  final String username;
  final String? email;
  final String fullName;
  final String role; // 'admin' or 'customer'
  final String status; // 'active' or 'locked'
  final String? phone;
  final String? address;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.username,
    this.email,
    required this.fullName,
    required this.role,
    required this.status,
    this.phone,
    this.address,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isLocked => status == 'locked';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String?,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'role': role,
      'status': status,
      'phone': phone,
      'address': address,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
