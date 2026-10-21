class EmployeeModel {
  final String id;
  final String employeeCode;
  final String fullName;
  final String email;
  final String phone;
  final String department;
  final String position;
  final double baseSalary;
  final String avatarUrl;
  final bool isActive;
  final DateTime joinDate;

  EmployeeModel({
    required this.id,
    required this.employeeCode,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.department,
    required this.position,
    required this.baseSalary,
    required this.avatarUrl,
    this.isActive = true,
    required this.joinDate,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id']?.toString() ?? '',
      employeeCode: json['employeeCode'] ?? 'NV-000',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      department: json['department'] ?? 'Phòng Công Nghệ',
      position: json['position'] ?? 'Chuyên viên',
      baseSalary: (json['baseSalary'] ?? 15000000).toDouble(),
      avatarUrl: json['avatarUrl'] ?? 'https://i.pravatar.cc/150?img=11',
      isActive: json['isActive'] ?? true,
      joinDate: DateTime.parse(json['joinDate'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeCode': employeeCode,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'department': department,
      'position': position,
      'baseSalary': baseSalary,
      'avatarUrl': avatarUrl,
      'isActive': isActive,
      'joinDate': joinDate.toIso8601String(),
    };
  }

  EmployeeModel copyWith({
    String? id,
    String? employeeCode,
    String? fullName,
    String? email,
    String? phone,
    String? department,
    String? position,
    double? baseSalary,
    String? avatarUrl,
    bool? isActive,
    DateTime? joinDate,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      employeeCode: employeeCode ?? this.employeeCode,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      position: position ?? this.position,
      baseSalary: baseSalary ?? this.baseSalary,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      joinDate: joinDate ?? this.joinDate,
    );
  }
}
