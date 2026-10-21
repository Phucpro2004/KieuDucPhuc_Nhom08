import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/api_service.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedDepartment = 'Phòng Công Nghệ';
  bool _isLoading = false;

  final List<String> _departments = [
    'Phòng Công Nghệ',
    'Phòng Nhân Sự',
    'Phòng Tài Chính',
    'Phòng Kinh Doanh',
    'Phòng Kỹ Thuật',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.warning,
          content: Text('Vui lòng điền đầy đủ họ tên, email và mật khẩu!'),
        ),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.warning,
          content: Text('Mật khẩu bảo mật phải có tối thiểu 8 ký tự!'),
        ),
      );
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.warning,
          content: Text('Vui lòng nhập địa chỉ email hợp lệ để nhận mã OTP!'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    // Luôn luôn đăng ký với vai trò 'employee' (Nhân viên)
    final res = await ApiService().registerAccount(
      fullName: fullName,
      email: email,
      password: password,
      role: 'employee',
      department: _selectedDepartment,
    );
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.success,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(res['message'] ?? 'Đã gửi mã OTP kích hoạt đến email thực của bạn!'),
              ),
            ],
          ),
        ),
      );

      // Chuyển sang màn hình xác thực mã OTP gửi về máy thực
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            email: email,
            isRegisterFlow: true,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.error,
          content: Text(res['message'] ?? 'Đăng ký không thành công. Vui lòng thử lại!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Đăng Ký Tài Khoản Nhân Viên'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppTheme.bgDark,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông Tin Nhân Sự Mới',
                        style: TextStyle(
                          color: AppTheme.textWhite,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Hệ thống sẽ gửi mã OTP xác nhận về email thực của bạn để kích hoạt tài khoản.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 20),

                      CustomTextField(
                        controller: _fullNameController,
                        label: 'Họ và Tên Nhân Viên',
                        hint: 'Nguyễn Văn A',
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _emailController,
                        label: 'Email Nhận Mã OTP (Email Thực)',
                        hint: 'nhanvien@gmail.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _passwordController,
                        label: 'Mật Khẩu',
                        hint: 'Tối thiểu 8 ký tự',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),

                      // Department Dropdown
                      const Text('Phòng Ban Trực Thuộc', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDepartment,
                        dropdownColor: AppTheme.bgCard,
                        style: const TextStyle(color: AppTheme.textWhite),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppTheme.bgCardLight.withOpacity(0.6),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          prefixIcon: const Icon(Icons.business_outlined, color: AppTheme.primaryGlow),
                        ),
                        items: _departments.map((dep) {
                          return DropdownMenuItem(value: dep, child: Text(dep));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedDepartment = val);
                        },
                      ),
                      const SizedBox(height: 18),

                      // Notification: Role is strictly Employee
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.badge_rounded, color: AppTheme.secondary, size: 24),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quyền hạn: Nhân Viên',
                                    style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Hệ thống chỉ cho phép nhân viên đăng ký. Quyền Admin được khởi tạo tài khoản riêng.',
                                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.mark_email_read_outlined, color: Colors.white, size: 20),
                                    SizedBox(width: 10),
                                    Text(
                                      'GỬI OTP VỀ EMAIL & ĐĂNG KÝ',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Đã có tài khoản? Đăng nhập ngay', style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
