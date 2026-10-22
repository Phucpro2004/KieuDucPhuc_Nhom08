import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/api_service.dart';
import '../main_navigation_screen.dart';
import 'register_screen.dart';
import 'otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Xóa tài khoản, mật khẩu mặc định để người dùng tự nhập tài khoản Admin/Nhân viên
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.warning,
          content: Text('Vui lòng nhập đầy đủ Email và Mật khẩu!'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final res = await ApiService().login(
      email: email,
      password: password,
    );
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (res['success'] == true) {
      final bool requireOtp = res['requireOtp'] == true;
      final bool isUnverified = res['isUnverifiedRegistration'] == true;
      final String role = (res['role'] ?? res['user']?['role'] ?? '').toString().toLowerCase();

      // NẾU LÀ ADMIN: ĐĂNG NHẬP TRỰC TIẾP KHÔNG CẦN OTP
      if (!requireOtp || role == 'admin') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.success,
            content: Row(
              children: [
                Icon(Icons.verified_user_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Đăng nhập quyền Quản trị viên (Admin) thành công!')),
              ],
            ),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      } else {
        // NẾU LÀ NHÂN VIÊN: BẮT BUỘC XÁC THỰC MÃ OTP QUA EMAIL (2FA) HOẶC KÍCH HOẠT
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: isUnverified ? AppTheme.warning : AppTheme.primary,
            content: Row(
              children: [
                const Icon(Icons.mark_email_unread_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(res['message'] ?? 'Mã xác thực OTP đã được gửi về email!'),
                ),
              ],
            ),
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              email: email,
              isRegisterFlow: isUnverified,
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.error,
          content: Text(res['message'] ?? 'Email hoặc mật khẩu không chính xác!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF0B0F19),
              Color(0xFF030712),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 25),
                // Logo & Header
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryGlow, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3),
                        blurRadius: 25,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.corporate_fare_rounded, size: 48, color: AppTheme.textWhite),
                ),
                const SizedBox(height: 18),
                Text(
                  'KIEU DUC PHUC GROUP',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 22,
                        letterSpacing: 2,
                        color: AppTheme.secondary,
                      ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hệ Thống Chấm Công & Quản Trị Nhân Sự Thông Minh',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Login Form Card
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đăng Nhập Hệ Thống',
                        style: TextStyle(
                          color: AppTheme.textWhite,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Nhập tài khoản Admin hoặc Nhân viên để truy cập',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 22),

                      CustomTextField(
                        controller: _emailController,
                        label: 'Email Tài Khoản',
                        hint: 'admin@company.com hoặc email nhân viên',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 18),

                      CustomTextField(
                        controller: _passwordController,
                        label: 'Mật Khẩu',
                        hint: 'Nhập mật khẩu của bạn',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: AppTheme.textMuted,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Information Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.secondary.withOpacity(0.25)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: AppTheme.secondary, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Admin đăng nhập trực tiếp. Nhân viên sẽ nhận mã OTP 2FA qua email để bảo mật.',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            shadowColor: AppTheme.primary.withOpacity(0.5),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'ĐĂNG NHẬP HỆ THỐNG',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Chưa có tài khoản nhân sự? ', style: TextStyle(color: AppTheme.textMuted)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        'Đăng ký nhân viên',
                        style: TextStyle(
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
