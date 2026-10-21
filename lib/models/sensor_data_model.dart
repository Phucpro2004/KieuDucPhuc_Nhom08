class SensorDataModel {
  final double noiseDb;         // Cường độ âm thanh (dB)
  final double accelerationMag; // Cường độ gia tốc chuyển động (m/s²)
  final double pressureHpa;     // Áp suất khí quyển (hPa)
  final bool isHumanPresent;    // Phát hiện hiện diện con người
  final String environmentType; // 'Văn phòng yên tĩnh', 'Phòng họp', 'Ngoại cảnh'

  SensorDataModel({
    required this.noiseDb,
    required this.accelerationMag,
    required this.pressureHpa,
    required this.isHumanPresent,
    required this.environmentType,
  });

  String get noiseStatus {
    if (noiseDb < 45) return 'Yên tĩnh (Phù hợp làm việc)';
    if (noiseDb < 70) return 'Mức trung bình (Phòng họp/Trao đổi)';
    return 'Ồn ào (Cần chú ý)';
  }

  String get motionStatus {
    if (accelerationMag < 0.5) return 'Đứng yên (Bàn làm việc)';
    if (accelerationMag < 3.0) return 'Di chuyển nhẹ (Văn phòng)';
    return 'Vận động mạnh (Đang đi lại)';
  }
}
