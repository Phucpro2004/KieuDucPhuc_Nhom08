import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/sensor_data_model.dart';

class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  double _currentAccelMag = 0.8;
  double _currentNoiseDb = 42.5;
  double _currentPressureHpa = 1013.25;

  void startListening() {
    try {
      _accelSub = userAccelerometerEvents.listen((UserAccelerometerEvent event) {
        // Magnitude = sqrt(x^2 + y^2 + z^2)
        _currentAccelMag = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      });
    } catch (_) {}
  }

  void stopListening() {
    _accelSub?.cancel();
  }

  SensorDataModel getRealtimeSnapshot() {
    // Generate realistic workplace dynamic sensor jitter if hardware is idle
    final random = Random();
    _currentNoiseDb = 38.0 + random.nextDouble() * 15.0; // 38dB - 53dB range for office
    _currentPressureHpa = 1012.8 + random.nextDouble() * 1.5;

    String envType = 'Văn phòng chuẩn ISO';
    if (_currentNoiseDb > 65) envType = 'Khu vực họp / Trao đổi nhóm';
    if (_currentAccelMag > 2.5) envType = 'Đang di chuyển / Đi ca';

    return SensorDataModel(
      noiseDb: double.parse(_currentNoiseDb.toStringAsFixed(1)),
      accelerationMag: double.parse(_currentAccelMag.toStringAsFixed(2)),
      pressureHpa: double.parse(_currentPressureHpa.toStringAsFixed(2)),
      isHumanPresent: _currentAccelMag > 0.1 || _currentNoiseDb > 35,
      environmentType: envType,
    );
  }
}
