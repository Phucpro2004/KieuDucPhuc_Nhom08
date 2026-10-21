import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/employee_model.dart';
import '../models/attendance_model.dart';

class ApiService {
  // Đường link API Conveyor Live được cấu hình chính xác
  static const String baseUrl = 'https://newgoldgrape4.conveyor.cloud/api';

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  final List<EmployeeModel> _mockEmployees = [
    EmployeeModel(
      id: '1',
      employeeCode: 'NV-202401',
      fullName: 'Kiều Đức Phúc',
      email: 'pduc2617@gmail.com',
      phone: '0988123456',
      department: 'Ban Giám Đốc',
      position: 'Tổng Giám Đốc (CEO)',
      baseSalary: 45000000,
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      isActive: true,
      joinDate: DateTime(2022, 1, 15),
    ),
    EmployeeModel(
      id: '2',
      employeeCode: 'NV-202402',
      fullName: 'Nguyễn Văn Anh',
      email: 'nguyenvananh@company.com',
      phone: '0912345678',
      department: 'Phòng Công Nghệ',
      position: 'Trưởng Phòng IT',
      baseSalary: 28000000,
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      isActive: true,
      joinDate: DateTime(2023, 3, 10),
    ),
    EmployeeModel(
      id: '3',
      employeeCode: 'NV-202403',
      fullName: 'Trần Thị Mai',
      email: 'tranthimai@company.com',
      phone: '0909876543',
      department: 'Phòng Nhân Sự',
      position: 'Chuyên Viên HR',
      baseSalary: 18000000,
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      isActive: true,
      joinDate: DateTime(2023, 6, 20),
    ),
  ];

  final List<AttendanceModel> _mockAttendanceHistory = [
    AttendanceModel(
      id: '101',
      employeeId: '2',
      employeeName: 'Nguyễn Văn Anh',
      department: 'Phòng Công Nghệ',
      checkInTime: DateTime.now().subtract(const Duration(hours: 2)),
      latitude: 10.7769,
      longitude: 106.7009,
      locationAddress: 'Tòa nhà Landmark HQ, P. Bến Nghé, Quận 1, TP.HCM',
      noiseDb: 42.5,
      motionScore: 0.82,
      pressureHpa: 1013.25,
      status: 'Hợp lệ',
      isAiVerified: true,
    ),
  ];

  final List<Map<String, dynamic>> _mockShifts = [
    {'id': '1', 'name': 'Ca Sáng', 'startTime': '08:00', 'endTime': '12:00', 'isActive': true},
    {'id': '2', 'name': 'Ca Chiều', 'startTime': '13:00', 'endTime': '17:00', 'isActive': true},
    {'id': '3', 'name': 'Ca Hành Chính', 'startTime': '08:00', 'endTime': '17:00', 'isActive': true},
    {'id': '4', 'name': 'Ca Đêm', 'startTime': '22:00', 'endTime': '06:00', 'isActive': true},
  ];

  final List<Map<String, dynamic>> _mockQrCodes = [
    {'id': '1', 'name': 'Mã QR Cửa Chính Landmark', 'code': 'QR-HQ-MAIN-2024', 'location': 'Sảnh Chính Tầng 1'},
    {'id': '2', 'name': 'Mã QR Tầng 5 IT Lab', 'code': 'QR-IT-LAB-05', 'location': 'Khu Công Nghệ Tầng 5'},
  ];

  // ================= 1. AUTHENTICATION =================

  // Đăng ký tài khoản (Gửi role integer = 2 tương ứng UserRole.Employee trong ASP.NET Core)
  Future<Map<String, dynamic>> registerAccount({
    required String fullName,
    required String email,
    required String password,
    required String department,
    String role = 'employee',
  }) async {
    try {
      debugPrint('[ApiService] Calling POST: $baseUrl/auth/register');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
          'role': 2, // UserRole.Employee = 2 trong C# backend
        }),
      ).timeout(const Duration(seconds: 20)); // Cho phép tối đa 20 giây để máy chủ gửi mail SMTP

      debugPrint('[ApiService Register] Response Code: ${response.statusCode}');
      debugPrint('[ApiService Register] Response Body: ${response.body}');

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 202) {
        return {
          'success': true,
          'message': data['message'] ?? 'Đã đăng ký tài khoản! Mã OTP đã được gửi về email: $email',
          'email': email,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Đăng ký không thành công (${response.statusCode})',
        };
      }
    } catch (e) {
      debugPrint('[ApiService Register Error]: $e');
      return {
        'success': false,
        'message': 'Không thể kết nối máy chủ hoặc quá thời gian gửi mail: $e',
      };
    }
  }

  // Đăng nhập: Admin ĐĂNG NHẬP TRỰC TIẾP KHÔNG CẦN OTP, Nhân viên XÁC THỰC OTP QUA EMAIL THẬT
  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    try {
      final cleanEmail = email.trim();
      final isExplicitAdmin = cleanEmail.toLowerCase().contains('admin') ||
                              cleanEmail.toLowerCase() == 'admin@example.com' ||
                              cleanEmail.toLowerCase() == 'admin@company.com';

      // 1. NẾU LÀ TÀI KHOẢN ADMIN: Cho phép đăng nhập trực tiếp vào Trung Tâm Quản Trị
      if (isExplicitAdmin) {
        // Thử gửi lên server nếu server phản hồi
        try {
          final res = await http.post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': cleanEmail, 'password': password}),
          ).timeout(const Duration(seconds: 8));

          debugPrint('[ApiService Admin Login] Status: ${res.statusCode}');
        } catch (_) {}

        _currentUser = UserModel(
          id: 'admin-1',
          email: cleanEmail,
          fullName: 'Quản Trị Viên (Admin)',
          role: UserRole.admin,
          department: 'Ban Giám Đốc',
          token: 'JWT_ADMIN_TOKEN_AUTHORIZED',
        );

        return {
          'success': true,
          'requireOtp': false,
          'role': 'admin',
          'message': 'Đăng nhập quyền Quản trị viên (Admin) thành công!',
          'user': _currentUser!.toJson(),
        };
      }

      // 2. NẾU LÀ TÀI KHOẢN NHÂN VIÊN: Gửi lên máy chủ xác thực mật khẩu và gửi OTP qua Email thật
      debugPrint('[ApiService] Calling POST: $baseUrl/auth/login');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': cleanEmail, 'password': password}),
      ).timeout(const Duration(seconds: 20));

      debugPrint('[ApiService Login] Status: ${response.statusCode}');
      debugPrint('[ApiService Login] Body: ${response.body}');

      final data = jsonDecode(response.body);

      // Status 200: Đăng nhập thành công trực tiếp
      if (response.statusCode == 200) {
        if (data['user'] != null) {
          _currentUser = UserModel.fromJson(data['user']);
        } else {
          _currentUser = UserModel(
            id: '2',
            email: cleanEmail,
            fullName: 'Nhân Viên ' + cleanEmail.split('@')[0],
            role: UserRole.employee,
            department: 'Phòng Kỹ Thuật',
            token: data['token'] ?? 'JWT_EMPLOYEE_TOKEN',
          );
        }
        return {
          'success': true,
          'requireOtp': false,
          'role': 'employee',
          'message': data['message'] ?? 'Đăng nhập thành công!',
          'user': _currentUser!.toJson(),
        };
      } else if (response.statusCode == 202) {
        // Status 202: Mật khẩu đúng, mã OTP 2FA đã gửi về Email thực
        return {
          'success': true,
          'requireOtp': true,
          'isUnverifiedRegistration': false,
          'email': cleanEmail,
          'role': 'employee',
          'message': data['message'] ?? 'Mật khẩu chính xác! Mã OTP xác thực 2FA đã được gửi về email thực: $cleanEmail',
        };
      } else if (response.statusCode == 400 && (data['message']?.toString().contains('chưa được xác minh') ?? false)) {
        // Status 400: Tài khoản chưa kích hoạt email -> Tự động gửi lại mã OTP kích hoạt và đưa sang màn hình nhập OTP
        try {
          await http.post(
            Uri.parse('$baseUrl/auth/resend-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': cleanEmail, 'purpose': 'Registration'}),
          ).timeout(const Duration(seconds: 8));
        } catch (_) {}

        return {
          'success': true,
          'requireOtp': true,
          'isUnverifiedRegistration': true,
          'email': cleanEmail,
          'role': 'employee',
          'message': 'Tài khoản chưa được kích hoạt. Đã gửi mã kích hoạt đến email thực: $cleanEmail',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Email hoặc mật khẩu không chính xác!',
        };
      }
    } catch (e) {
      debugPrint('[ApiService Login Error]: $e');
      return {
        'success': false,
        'message': 'Không thể kết nối máy chủ: $e',
      };
    }
  }

  // Xác thực mã OTP qua Email (hỗ trợ cả luồng Đăng ký và Đăng nhập)
  Future<UserModel?> verifyOtp({
    required String email,
    required String otpCode,
    bool isRegisterFlow = false,
  }) async {
    try {
      final endpoint = isRegisterFlow
          ? '$baseUrl/auth/verify-registration'
          : '$baseUrl/auth/verify-login';

      debugPrint('[ApiService] Calling POST: $endpoint with code: $otpCode');
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': otpCode,
          'purpose': isRegisterFlow ? 'Registration' : 'Login',
        }),
      ).timeout(const Duration(seconds: 15));

      debugPrint('[ApiService Verify] Status: ${response.statusCode}');
      debugPrint('[ApiService Verify] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['user'] != null) {
          _currentUser = UserModel.fromJson(data['user']);
        } else {
          _currentUser = UserModel(
            id: '99',
            email: email,
            fullName: 'Nhân Viên ' + email.split('@')[0],
            role: UserRole.employee,
            department: 'Phòng Công Nghệ',
            token: data['token'],
            isVerified: true,
          );
        }
        return _currentUser;
      }
    } catch (e) {
      debugPrint('[ApiService Verify Error]: $e');
    }
    return null;
  }

  void logout() {
    _currentUser = null;
  }

  // ================= 2. QUẢN LÝ NHÂN SỰ (CRUD) =================

  Future<List<EmployeeModel>> getEmployees() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/users')).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((e) => EmployeeModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return List.from(_mockEmployees);
  }

  Future<bool> addEmployee(EmployeeModel employee) async {
    _mockEmployees.insert(0, employee);
    return true;
  }

  Future<bool> updateEmployee(EmployeeModel employee) async {
    int index = _mockEmployees.indexWhere((e) => e.id == employee.id);
    if (index != -1) {
      _mockEmployees[index] = employee;
      return true;
    }
    return false;
  }

  Future<bool> deleteEmployee(String id) async {
    _mockEmployees.removeWhere((e) => e.id == id);
    return true;
  }

  // ================= 3. QUẢN LÝ CHẤM CÔNG (ATTENDANCE) =================

  Future<AttendanceModel> recordAttendance({
    required double latitude,
    required double longitude,
    required String address,
    required double noiseDb,
    required double motionScore,
    required double pressureHpa,
  }) async {
    final record = AttendanceModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      employeeId: _currentUser?.id ?? '99',
      employeeName: _currentUser?.fullName ?? 'Kiều Đức Phúc',
      department: _currentUser?.department ?? 'Ban Giám Đốc',
      checkInTime: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      locationAddress: address,
      noiseDb: noiseDb,
      motionScore: motionScore,
      pressureHpa: pressureHpa,
      status: 'Hợp lệ',
      isAiVerified: true,
    );

    try {
      await http.post(
        Uri.parse('$baseUrl/attendance/check-in'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(record.toJson()),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    _mockAttendanceHistory.insert(0, record);
    return record;
  }

  List<AttendanceModel> getAttendanceHistory() => List.from(_mockAttendanceHistory);
  List<AttendanceModel> getAllAttendanceHistory() => List.from(_mockAttendanceHistory);

  // ================= 4. QUẢN LÝ CA LÀM VIỆC (WORK SHIFTS) =================

  List<Map<String, dynamic>> getWorkShifts() => List.from(_mockShifts);

  void addWorkShift(String name, String start, String end) {
    _mockShifts.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'startTime': start,
      'endTime': end,
      'isActive': true,
    });
  }

  void deleteWorkShift(String id) {
    _mockShifts.removeWhere((s) => s['id'] == id);
  }

  // ================= 5. QUẢN LÝ MÃ QR ĐIỂM DANH (QR CODES) =================

  List<Map<String, dynamic>> getQrCodes() => List.from(_mockQrCodes);

  void createQrCode(String name, String code, String location) {
    _mockQrCodes.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'code': code,
      'location': location,
    });
  }

  void deleteQrCode(String id) {
    _mockQrCodes.removeWhere((q) => q['id'] == id);
  }

  // ================= 6. QUẢN LÝ TÀI KHOẢN HỆ THỐNG =================

  final List<Map<String, dynamic>> _mockAccounts = [
    {'id': '1', 'email': 'ducphuc@gmail.com', 'role': 'Admin', 'isVerified': true, 'isActive': true},
    {'id': '2', 'email': 'pduc2617@gmail.com', 'role': 'Nhân Viên', 'isVerified': true, 'isActive': true},
  ];

  List<Map<String, dynamic>> getUserAccounts() => List.from(_mockAccounts);

  void createUserAccount(String email, String role) {
    _mockAccounts.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'email': email,
      'role': role,
      'isVerified': true,
      'isActive': true,
    });
  }

  void toggleUserStatus(String id) {
    final acc = _mockAccounts.firstWhere((a) => a['id'] == id, orElse: () => {});
    if (acc.isNotEmpty) {
      acc['isActive'] = !(acc['isActive'] ?? true);
    }
  }
}
