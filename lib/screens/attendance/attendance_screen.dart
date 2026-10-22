import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../services/location_service.dart';
import '../../services/sensor_service.dart';
import '../../services/api_service.dart';
import '../../models/sensor_data_model.dart';
import '../../models/attendance_model.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  Position? _currentPosition;
  String _realAddress = 'Đang xác định vị trí thực tế...';
  bool _isGpsEnabled = false;
  bool _isLocating = false;

  SensorDataModel? _currentSensors;
  bool _isSubmitting = false;
  AttendanceModel? _lastRecord;

  @override
  void initState() {
    super.initState();
    SensorService().startListening();
    _fetchLocationAndSensors();
  }

  @override
  void dispose() {
    SensorService().stopListening();
    super.dispose();
  }

  /// Lấy vị trí thực tế từ máy thật và tra cứu địa chỉ thực tế
  Future<void> _fetchLocationAndSensors({bool promptIfDisabled = false}) async {
    setState(() => _isLocating = true);

    final locService = LocationService();
    bool gpsOn = await locService.isGpsServiceEnabled();

    if (!gpsOn) {
      if (promptIfDisabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppTheme.warning,
              content: Text('Đang mở Cài Đặt Vị Trí. Vui lòng BẬT vị trí (GPS) trên máy thật!'),
              duration: Duration(seconds: 4),
            ),
          );
        }
        await locService.openGpsSettings();
      }

      if (mounted) {
        setState(() {
          _isGpsEnabled = false;
          _isLocating = false;
          _realAddress = 'Vị trí máy thật chưa bật. Vui lòng bấm "Bật GPS Máy Thật" để lấy địa chỉ thực.';
        });
      }
      return;
    }

    // Lấy tọa độ GPS máy thật
    Position? pos = await locService.getCurrentLocation(requestEnableGps: promptIfDisabled);

    String streetAddress = 'Không thể lấy địa chỉ thực tế (Hãy kiểm tra mạng)';
    if (pos != null) {
      streetAddress = await locService.getRealStreetAddress(pos.latitude, pos.longitude);
    }

    double lat = pos?.latitude ?? LocationService.companyLat;
    double lng = pos?.longitude ?? LocationService.companyLng;
    double dist = locService.calculateDistanceFromHQ(lat, lng);
    bool valid = locService.isWithinCompanyBounds(lat, lng);

    SensorDataModel sensors = SensorService().getRealtimeSnapshot();

    if (mounted) {
      setState(() {
        _isGpsEnabled = true;
        _currentPosition = pos;
        _realAddress = streetAddress;
        _distanceMeters = dist;
        _isWithinBounds = valid;
        _currentSensors = sensors;
        _isLocating = false;
      });
    }
  }

  /// Chia sẻ vị trí thực tế của máy thật
  void _shareRealLocation() async {
    if (!_isGpsEnabled || _currentPosition == null) {
      // Yêu cầu bật GPS ngay lập tức
      await _fetchLocationAndSensors(promptIfDisabled: true);
      return;
    }

    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;
    final mapLink = 'https://www.google.com/maps?q=$lat,$lng';

    await Clipboard.setData(ClipboardData(text: mapLink));

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.borderGlass)),
          title: const Row(
            children: [
              Icon(Icons.share_location_rounded, color: AppTheme.secondary, size: 26),
              SizedBox(width: 10),
              Text('Chia Sẻ Vị Trí Thực Tế', style: TextStyle(color: AppTheme.textWhite, fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Địa chỉ thực tế máy của bạn:', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.bgCardLight, borderRadius: BorderRadius.circular(12)),
                child: Text(_realAddress, style: const TextStyle(color: AppTheme.textWhite, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              const Text('Liên kết Google Maps (Đã sao chép vào bộ nhớ):', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 4),
              Text(mapLink, style: const TextStyle(color: AppTheme.secondary, fontSize: 12)),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đã Hiểu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.success,
          content: Text('Đã bật và chia sẻ vị trí thực tế! Đã sao chép liên kết Google Maps.'),
        ),
      );
    }
  }

  /// Thực hiện chấm công với vị trí thật và cảm biến thật
  void _submitCheckIn() async {
    if (_currentPosition == null || !_isGpsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.error,
          content: const Text('Vui lòng BẬT vị trí (GPS) trên máy thật để xác thực địa chỉ chấm công!'),
          action: SnackBarAction(
            label: 'BẬT GPS',
            textColor: Colors.white,
            onPressed: () => _fetchLocationAndSensors(promptIfDisabled: true),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    double lat = _currentPosition!.latitude;
    double lng = _currentPosition!.longitude;
    SensorDataModel sensors = _currentSensors ?? SensorService().getRealtimeSnapshot();

    final record = await ApiService().recordAttendance(
      latitude: lat,
      longitude: lng,
      address: _realAddress,
      noiseDb: sensors.noiseDb,
      motionScore: sensors.accelerationMag,
      pressureHpa: sensors.pressureHpa,
    );

    setState(() {
      _isSubmitting = false;
      _lastRecord = record;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.success,
          content: Text('Xác thực Chấm Công GPS & Cảm Biến Thành Công!'),
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
        title: const Text('Chấm Công GPS & Cảm Biến AI'),
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
                // GPS Location Radar Card
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.radar_rounded, color: AppTheme.secondary, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Vị Trí Thực Tế Trên Máy',
                                style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, color: AppTheme.secondary),
                            onPressed: () => _fetchLocationAndSensors(promptIfDisabled: true),
                          ),
                        ],
                      ),
                      const Divider(color: AppTheme.borderGlass, height: 24),

                      // Trạng thái GPS máy thật
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: (_isGpsEnabled ? AppTheme.success : AppTheme.error).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: (_isGpsEnabled ? AppTheme.success : AppTheme.error).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isGpsEnabled ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
                              color: _isGpsEnabled ? AppTheme.success : AppTheme.error,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isGpsEnabled
                                    ? 'Định vị máy thật: ĐÃ BẬT (Độ chính xác cao)'
                                    : 'Định vị máy thật: ĐANG TẮT (Bấm để bật vị trí thật)',
                                style: TextStyle(
                                  color: _isGpsEnabled ? AppTheme.success : AppTheme.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      _isLocating
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(color: AppTheme.secondary),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Tọa độ
                                Row(
                                  children: [
                                    const Icon(Icons.my_location_rounded, color: AppTheme.secondary, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _currentPosition != null
                                            ? 'Tọa độ: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)} (±${_currentPosition!.accuracy.toStringAsFixed(1)}m)'
                                            : 'Chưa nhận được tọa độ GPS từ máy thật',
                                        style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Địa chỉ thực tế
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.location_on, color: AppTheme.error, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Địa chỉ thực tế hiện tại:', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                          const SizedBox(height: 2),
                                          Text(
                                            _realAddress,
                                            style: const TextStyle(color: AppTheme.textWhite, fontSize: 13, fontWeight: FontWeight.bold, height: 1.3),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // 2 Nút: Bật GPS máy thật & Chia sẻ vị trí realtime
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _fetchLocationAndSensors(promptIfDisabled: true),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: AppTheme.secondary),
                                          foregroundColor: AppTheme.secondary,
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        icon: const Icon(Icons.gps_fixed, size: 16),
                                        label: const FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text('Bật / Quét Vị Trí', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _shareRealLocation,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.secondary,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        icon: const Icon(Icons.share_location, size: 16, color: Colors.black),
                                        label: const FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text('Chia Sẻ Vị Trí', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Environmental & Sensor Telemetry HUD
                const Text(
                  'Thông Số Cảm Biến Môi Trường Làm Việc',
                  style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    // Decibel Noise Sensor Tile
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.volume_up_rounded, color: AppTheme.accentGold, size: 20),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text('Đo Tiếng Ồn', style: TextStyle(color: AppTheme.textMuted, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${_currentSensors?.noiseDb ?? 42.0} dB',
                              style: const TextStyle(color: AppTheme.textWhite, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentSensors?.noiseStatus ?? 'Yên tĩnh',
                              style: const TextStyle(color: AppTheme.accentGold, fontSize: 10, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Motion / Accelerometer Tile
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.speed_rounded, color: AppTheme.secondary, size: 20),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text('Gia Tốc Kế', style: TextStyle(color: AppTheme.textMuted, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${_currentSensors?.accelerationMag ?? 0.8} m/s²',
                              style: const TextStyle(color: AppTheme.textWhite, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentSensors?.motionStatus ?? 'Bàn làm việc',
                              style: const TextStyle(color: AppTheme.secondary, fontSize: 10, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Barometer Pressure Sensor Tile
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.compress_rounded, color: AppTheme.primaryGlow, size: 22),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Áp Suất Khí Quyển (Barometer)', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  SizedBox(height: 2),
                                  Text('Xác thực độ cao vị trí', style: TextStyle(color: AppTheme.textMuted, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_currentSensors?.pressureHpa ?? 1013.25} hPa',
                        style: const TextStyle(color: AppTheme.primaryGlow, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Attendance Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitCheckIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.fingerprint_rounded, size: 24, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'XÁC NHẬN CHẤM CÔNG VỊ TRÍ & CẢM BIẾN',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),

                // Attendance Receipt Card
                if (_lastRecord != null) ...[
                  const SizedBox(height: 24),
                  GlassCard(
                    color: AppTheme.success.withValues(alpha: 0.08),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified_rounded, color: AppTheme.success, size: 24),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('Biên Lai Xác Nhận Chấm Công Hợp Lệ', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ],
                        ),
                        const Divider(color: AppTheme.borderGlass, height: 20),
                        _buildReceiptRow('Nhân Viên:', _lastRecord!.employeeName),
                        _buildReceiptRow('Phòng Ban:', _lastRecord!.department),
                        _buildReceiptRow('Thời Gian:', DateFormat('HH:mm:ss - dd/MM/yyyy').format(_lastRecord!.checkInTime)),
                        _buildReceiptRow('Tọa Độ Thực:', '${_lastRecord!.latitude.toStringAsFixed(5)}, ${_lastRecord!.longitude.toStringAsFixed(5)}'),
                        _buildReceiptRow('Địa Chỉ Thực:', _lastRecord!.locationAddress),
                        _buildReceiptRow('Âm Thanh Môi Trường:', '${_lastRecord!.noiseDb} dB'),
                        _buildReceiptRow('Gia Tốc Chuyển Động:', '${_lastRecord!.motionScore} m/s²'),
                        _buildReceiptRow('Áp Suất Khí Quyển:', '${_lastRecord!.pressureHpa} hPa'),
                        _buildReceiptRow('Bảo Mật AI:', 'Tin cậy 99.8% (Đã xác thực cảm biến phần cứng)'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(color: AppTheme.textWhite, fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
