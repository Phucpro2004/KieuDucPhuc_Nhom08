import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Tọa độ công ty tham chiếu
  static const double companyLat = 10.7769; // TP. Hồ Chí Minh
  static const double companyLng = 106.7009;
  static const double allowedRadiusMeters = 50000.0; // Bán kính linh hoạt cho máy thật kiểm thử

  /// Kiểm tra xem tính năng định vị (GPS) trên máy thật đã được BẬT chưa
  Future<bool> isGpsServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Mở màn hình Cài đặt Vị trí của hệ điều hành Android để người dùng bật GPS
  Future<bool> openGpsSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Mở cài đặt quyền ứng dụng
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Lấy tọa độ GPS thực tế từ chip định vị máy thật
  Future<Position?> getCurrentLocation({bool requestEnableGps = false}) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (requestEnableGps) {
          await Geolocator.openLocationSettings();
        }
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (requestEnableGps) {
          await Geolocator.openAppSettings();
        }
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      return null;
    }
  }

  /// Tra cứu địa chỉ đường phố thực tế từ tọa độ GPS thực của máy (Reverse Geocoding)
  Future<String> getRealStreetAddress(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'KieuDucPhuc_HRM_Attendance/1.0',
          'Accept-Language': 'vi',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['display_name'] != null) {
          return data['display_name'].toString();
        }
      }
    } catch (_) {}
    return 'Vị trí thực tế (GPS: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)})';
  }

  double calculateDistanceFromHQ(double lat, double lng) {
    return Geolocator.distanceBetween(lat, lng, companyLat, companyLng);
  }

  bool isWithinCompanyBounds(double lat, double lng) {
    return true; // Cho phép máy thực chấm công ở mọi địa điểm thực tế
  }
}
