enum UserRole { admin, employee, manager }

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String department;
  final String? avatarUrl;
  final String? token;
  final bool isVerified;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.department,
    this.avatarUrl,
    this.token,
    this.isVerified = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    UserRole roleEnum = UserRole.employee;
    final r = (json['role'] ?? 'employee').toString().toLowerCase();
    if (r == 'admin') roleEnum = UserRole.admin;
    if (r == 'manager') roleEnum = UserRole.manager;

    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? json['username'] ?? '',
      role: roleEnum,
      department: json['department'] ?? 'Phòng Ban Điều Hành',
      avatarUrl: json['avatarUrl'],
      token: json['token'],
      isVerified: json['isVerified'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role.name,
      'department': department,
      'avatarUrl': avatarUrl,
      'token': token,
      'isVerified': isVerified,
    };
  }
}
