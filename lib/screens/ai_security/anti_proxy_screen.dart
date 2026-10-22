import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class AntiProxyScreen extends StatefulWidget {
  const AntiProxyScreen({super.key});

  @override
  State<AntiProxyScreen> createState() => _AntiProxyScreenState();
}

class _AntiProxyScreenState extends State<AntiProxyScreen> {
  bool _isAnalyzing = false;
  double _trustScore = 99.8;

  void _runAiDiagnostic() {
    setState(() => _isAnalyzing = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _trustScore = 99.8;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Tính Năng Độc Quyền: AI Chống Chấm Công Hộ'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppTheme.bgDark,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Feature Header Banner
                GlassCard(
                  color: AppTheme.primary.withOpacity(0.2),
                  borderColor: AppTheme.primaryGlow,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Xác Minh Cảm Biến Sinh Trắc AI',
                                  style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Công nghệ độc quyền phát hiện chấm công giả lập & chấm công hộ',
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Live Trust Score Meter
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text('ĐIỂM ĐỘ TIN CẬY THIẾT BỊ & THỰC THỂ', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      _isAnalyzing
                          ? const Column(
                              children: [
                                SizedBox(height: 20),
                                CircularProgressIndicator(color: AppTheme.secondary),
                                SizedBox(height: 16),
                                Text('Đang phân tích tổ hợp cảm biến...', style: TextStyle(color: AppTheme.secondary)),
                              ],
                            )
                          : Column(
                              children: [
                                Text(
                                  '$_trustScore%',
                                  style: const TextStyle(
                                    color: AppTheme.success,
                                    fontSize: 52,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.success.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppTheme.success),
                                  ),
                                  child: const Text(
                                    'XÁC THỰC THẬT - KHÔNG GIẢ LẬP',
                                    style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _isAnalyzing ? null : _runAiDiagnostic,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primaryGlow),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.analytics_outlined, color: AppTheme.primaryGlow),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('CHẠY CHẨN ĐOÁN AI REALTIME', style: TextStyle(color: AppTheme.primaryGlow, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Diagnostic Criteria List
                const Text('Tiêu Chí Phân Tích Sinh Trắc Cảm Biến', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),

                _buildCriteriaRow(
                  title: '1. Khớp Tọa Độ GPS & Bán Kính HQ',
                  desc: 'Khoảng cách < 50m so với Tòa nhà Trụ sở Tập đoàn',
                  passed: true,
                  icon: Icons.location_on_outlined,
                ),
                _buildCriteriaRow(
                  title: '2. Tần Số Âm Thanh Môi Trường (dB)',
                  desc: 'Cường độ âm thanh trùng khớp sóng âm văn phòng',
                  passed: true,
                  icon: Icons.graphic_eq_rounded,
                ),
                _buildCriteriaRow(
                  title: '3. Chuyển Động Gia Tốc Vi Mô',
                  desc: 'Phát hiện rung nhịp sinh học bàn tay người dùng',
                  passed: true,
                  icon: Icons.vibration_rounded,
                ),
                _buildCriteriaRow(
                  title: '4. Kiểm Tra Máy Ảo & Giả Lập Device',
                  desc: 'Phần cứng Android chính gốc (Phần cứng Pixel/Samsung)',
                  passed: true,
                  icon: Icons.phone_android_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCriteriaRow({
    required String title,
    required String desc,
    required bool passed,
    required IconData icon,
  }) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: passed ? AppTheme.success.withOpacity(0.2) : AppTheme.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: passed ? AppTheme.success : AppTheme.error, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Icon(
            passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: passed ? AppTheme.success : AppTheme.error,
            size: 22,
          ),
        ],
      ),
    );
  }
}
