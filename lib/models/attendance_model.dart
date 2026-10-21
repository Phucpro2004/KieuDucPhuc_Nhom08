class AttendanceModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String department;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final double latitude;
  final double longitude;
  final String locationAddress;
  final double noiseDb;
  final double motionScore;
  final double pressureHpa;
  final String status; // 'Thành công', 'Đến muộn', 'Nghi vấn'
  final bool isAiVerified;

  AttendanceModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.department,
    required this.checkInTime,
    this.checkOutTime,
    required this.latitude,
    required this.longitude,
    required this.locationAddress,
    required this.noiseDb,
    required this.motionScore,
    required this.pressureHpa,
    required this.status,
    this.isAiVerified = true,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      employeeName: json['employeeName'] ?? 'Nhân viên',
      department: json['department'] ?? 'Phòng Hành Chính',
      checkInTime: DateTime.parse(json['checkInTime'] ?? DateTime.now().toIso8601String()),
      checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']) : null,
      latitude: (json['latitude'] ?? 21.028511).toDouble(),
      longitude: (json['longitude'] ?? 105.804817).toDouble(),
      locationAddress: json['locationAddress'] ?? 'Tòa nhà Landmark, Hà Nội',
      noiseDb: (json['noiseDb'] ?? 45.0).toDouble(),
      motionScore: (json['motionScore'] ?? 1.2).toDouble(),
      pressureHpa: (json['pressureHpa'] ?? 1013.25).toDouble(),
      status: json['status'] ?? 'Thành công',
      isAiVerified: json['isAiVerified'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'department': department,
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'locationAddress': locationAddress,
      'noiseDb': noiseDb,
      'motionScore': motionScore,
      'pressureHpa': pressureHpa,
      'status': status,
      'isAiVerified': isAiVerified,
    };
  }
}
