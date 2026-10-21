import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../services/sensor_service.dart';
import '../../models/sensor_data_model.dart';

class SensorMonitorScreen extends StatefulWidget {
  const SensorMonitorScreen({super.key});

  @override
  State<SensorMonitorScreen> createState() => _SensorMonitorScreenState();
}

class _SensorMonitorScreenState extends State<SensorMonitorScreen> {
  late SensorDataModel _data;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    SensorService().startListening();
    _data = SensorService().getRealtimeSnapshot();
    _ticker = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (mounted) {
        setState(() {
          _data = SensorService().getRealtimeSnapshot();
        });
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    SensorService().stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Trạm Cảm Biến Môi Trường Realtime'),
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
                // Environment Type Hero Banner
                GlassCard(
                  color: AppTheme.secondary.withOpacity(0.15),
                  borderColor: AppTheme.secondary,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.sensors_rounded, color: AppTheme.secondary, size: 32),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Môi Trường Hiện Tại', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                            const SizedBox(height: 2),
                            Text(
                              _data.environmentType,
                              style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 1. Noise Decibel Meter Card
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.graphic_eq_rounded, color: AppTheme.accentGold, size: 24),
                              SizedBox(width: 8),
                              Text('1. Cường Độ Tiếng Ồn (Decibel dB)', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_data.noiseDb}',
                            style: const TextStyle(color: AppTheme.accentGold, fontSize: 42, fontWeight: FontWeight.bold),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8, left: 4),
                            child: Text('dB', style: TextStyle(color: AppTheme.textMuted, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(_data.noiseStatus, style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Animated dB Bar Visualizer
                      LinearProgressIndicator(
                        value: (_data.noiseDb / 100).clamp(0.0, 1.0),
                        backgroundColor: AppTheme.bgCardLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Motion Accelerometer Sensor Card
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.directions_run_rounded, color: AppTheme.secondary, size: 24),
                          SizedBox(width: 8),
                          Text('2. Cảm Biến Chuyển Động (Gia Tốc m/s²)', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_data.accelerationMag}',
                            style: const TextStyle(color: AppTheme.secondary, fontSize: 42, fontWeight: FontWeight.bold),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8, left: 4),
                            child: Text('m/s²', style: TextStyle(color: AppTheme.textMuted, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.secondary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(_data.motionStatus, style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      LinearProgressIndicator(
                        value: (_data.accelerationMag / 10.0).clamp(0.0, 1.0),
                        backgroundColor: AppTheme.bgCardLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondary),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Pressure Barometer Sensor Card
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.compress_rounded, color: AppTheme.primaryGlow, size: 24),
                          SizedBox(width: 8),
                          Text('3. Cảm Biến Áp Suất Khí Quyển (Barometer)', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_data.pressureHpa}',
                            style: const TextStyle(color: AppTheme.primaryGlow, fontSize: 38, fontWeight: FontWeight.bold),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8, left: 4),
                            child: Text('hPa', style: TextStyle(color: AppTheme.textMuted, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Bình Thường (Mặt biển)', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
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
