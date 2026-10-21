import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'dashboard/dashboard_screen.dart';
import 'attendance/attendance_screen.dart';
import 'admin/admin_management_screen.dart';
import 'video_call/group_video_call_screen.dart';
import 'sensor/sensor_monitor_screen.dart';
import 'ai_security/anti_proxy_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ApiService().currentUser;
    final isAdmin = user?.role == UserRole.admin;

    final List<Widget> pages = [
      const DashboardScreen(),
      const AttendanceScreen(), // GPS Location Sharing & Sensor Check-in
      if (isAdmin)
        const AdminManagementScreen() // Trung Tâm Quản Trị Toàn Diện Cho Admin
      else
        const SensorMonitorScreen(), // Sensor Monitoring Cho Nhân Viên
      const GroupVideoCallScreen(), // Group Video Call
      const AntiProxyScreen(), // AI Anti-Proxy Sensor Security
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard.withOpacity(0.95),
          border: const Border(top: BorderSide(color: AppTheme.borderGlass, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.secondary,
          unselectedItemColor: AppTheme.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Tổng Quan',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.location_on_rounded),
              label: 'Chấm Công GPS',
            ),
            BottomNavigationBarItem(
              icon: Icon(isAdmin ? Icons.admin_panel_settings_rounded : Icons.sensors_rounded),
              label: isAdmin ? 'Quản Trị Admin' : 'Cảm Biến',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.video_call_rounded),
              label: 'Họp Nhóm',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.security_rounded),
              label: 'Bảo Mật AI',
            ),
          ],
        ),
      ),
    );
  }
}
