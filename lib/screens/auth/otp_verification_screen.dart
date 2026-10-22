import 'login_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../services/api_service.dart';
import '../main_navigation_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final bool isRegisterFlow;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.isRegisterFlow,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isVerifying = false;
  int _timerSeconds = 120;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    setState(() => _timerSeconds = 120);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _verifyOtp() async {
    String otpCode = _controllers.map((c) => c.text).join();
    if (otpCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ 6 chữ số mã OTP!')),
      );
      return;
    }

    setState(() => _isVerifying = true);
    final user = await ApiService().verifyOtp(email: widget.email, otpCode: otpCode, isRegisterFlow: widget.isRegisterFlow);
    setState(() => _isVerifying = false);

    if (!mounted) return;

    if (user != null) {
      if (widget.isRegisterFlow) {
        // ĐĂNG KÝ: Báo kích hoạt thành công & chuyển ngay về giao diện đăng nhập
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.success,
            content: Text('Kích hoạt tài khoản thành công! Vui lòng đăng nhập với email ${widget.email}'),
            duration: const Duration(seconds: 4),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } else {
        // ĐĂNG NHẬP NHÂN VIÊN: Vào hệ thống
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.success,
            content: Text('Xác thực OTP 2FA thành công! Chào mừng ${user.fullName}'),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.error,
          content: Text('Mã OTP không đúng hoặc đã hết hạn! Vui lòng kiểm tra lại email.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.isRegisterFlow ? 'Kích Hoạt Tài Khoản Nhân Viên' : 'Xác Thực Đăng Nhập 2FA';
    final descText = widget.isRegisterFlow
        ? 'Hệ thống đã gửi mã OTP xác thực 6 số đến email thực của bạn:\n${widget.email}\nNhập mã để hoàn tất đăng ký tài khoản.'
        : 'Mã xác thực bảo mật 2 lớp (2FA) đã được gửi đến email:\n${widget.email}\nNhập mã để đăng nhập vào hệ thống.';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(titleText),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.isRegisterFlow) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppTheme.bgDark,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                const Icon(Icons.mark_email_read_outlined, size: 60, color: AppTheme.primaryGlow),
                const SizedBox(height: 16),

                Text(
                  'Xác Minh Mã OTP 6 Số',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, color: AppTheme.textWhite),
                ),
                const SizedBox(height: 8),
                Text(
                  descText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 24),

                // OTP Inputs
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (index) {
                          return SizedBox(
                            width: 38,
                            height: 55,
                            child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondary,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: AppTheme.bgCardLight,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.borderGlass),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.secondary, width: 2),
                                ),
                              ),
                              onChanged: (value) {
                                if (value.isNotEmpty && index < 5) {
                                  _focusNodes[index + 1].requestFocus();
                                }
                                if (value.isEmpty && index > 0) {
                                  _focusNodes[index - 1].requestFocus();
                                }
                                if (_controllers.every((c) => c.text.isNotEmpty)) {
                                  _verifyOtp();
                                }
                              },
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      // Countdown Timer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer_outlined, color: AppTheme.accentGold, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Hết hạn sau: ${_timerSeconds ~/ 60}:${(_timerSeconds % 60).toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: AppTheme.accentGold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isVerifying ? null : _verifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isVerifying
                              ? const CircularProgressIndicator(color: Colors.white)
                              : FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    widget.isRegisterFlow ? 'XÁC NHẬN KÍCH HOẠT' : 'XÁC NHẬN & ĐĂNG NHẬP',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                TextButton(
                  onPressed: _timerSeconds == 0 ? _startCountdown : null,
                  child: Text(
                    _timerSeconds == 0 ? 'Gửi lại mã OTP tới email' : 'Chưa nhận được mail? Chờ đếm ngược kết thúc',
                    style: TextStyle(
                      color: _timerSeconds == 0 ? AppTheme.secondary : AppTheme.textMuted,
                    ),
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
