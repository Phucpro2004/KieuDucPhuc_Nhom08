import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_text_field.dart';
import '../../models/employee_model.dart';
import '../../models/attendance_model.dart';
import '../../services/api_service.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  // Tab 1: Nhân Sự
  List<EmployeeModel> _employees = [];
  List<EmployeeModel> _filteredEmployees = [];
  String _employeeSearch = '';
  String _selectedDepFilter = 'Tất cả';

  // Tab 2: Chấm Công
  List<AttendanceModel> _attendanceLogs = [];

  // Tab 3: Ca Làm
  List<Map<String, dynamic>> _shifts = [];

  // Tab 4: Mã QR
  List<Map<String, dynamic>> _qrCodes = [];

  // Tab 5: Tài Khoản
  List<Map<String, dynamic>> _userAccounts = [];

  bool _isLoading = false;

  final List<String> _departments = [
    'Tất cả',
    'Ban Giám Đốc',
    'Phòng Công Nghệ',
    'Phòng Nhân Sự',
    'Phòng Tài Chính',
    'Phòng Kinh Doanh',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAllData() async {
    setState(() => _isLoading = true);
    final emps = await ApiService().getEmployees();
    final atts = ApiService().getAllAttendanceHistory();
    final shifts = ApiService().getWorkShifts();
    final qrs = ApiService().getQrCodes();
    final accs = ApiService().getUserAccounts();

    setState(() {
      _employees = emps;
      _attendanceLogs = atts;
      _shifts = shifts;
      _qrCodes = qrs;
      _userAccounts = accs;
      _applyEmployeeFilter();
      _isLoading = false;
    });
  }

  void _applyEmployeeFilter() {
    setState(() {
      _filteredEmployees = _employees.where((emp) {
        bool matchDep = _selectedDepFilter == 'Tất cả' || emp.department == _selectedDepFilter;
        bool matchSearch = emp.fullName.toLowerCase().contains(_employeeSearch.toLowerCase()) ||
            emp.employeeCode.toLowerCase().contains(_employeeSearch.toLowerCase()) ||
            emp.email.toLowerCase().contains(_employeeSearch.toLowerCase());
        return matchDep && matchSearch;
      }).toList();
    });
  }

  // ================= DIALOGS =================

  void _showAddEmployeeDialog() {
    final codeCtrl = TextEditingController(text: 'NV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final posCtrl = TextEditingController();
    final salaryCtrl = TextEditingController(text: '15000000');
    String depVal = 'Phòng Công Nghệ';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.borderGlass)),
        title: const Row(
          children: [
            Icon(Icons.person_add_rounded, color: AppTheme.secondary),
            SizedBox(width: 10),
            Text('Thêm Nhân Sự Mới', style: TextStyle(color: AppTheme.textWhite, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(controller: codeCtrl, label: 'Mã Nhân Viên', hint: 'NV-2024...'),
              const SizedBox(height: 12),
              CustomTextField(controller: nameCtrl, label: 'Họ và Tên', hint: 'Nguyễn Văn A'),
              const SizedBox(height: 12),
              CustomTextField(controller: emailCtrl, label: 'Email', hint: 'email@company.com'),
              const SizedBox(height: 12),
              CustomTextField(controller: phoneCtrl, label: 'Số Điện Thoại', hint: '0901234567'),
              const SizedBox(height: 12),
              CustomTextField(controller: posCtrl, label: 'Chức Vụ', hint: 'Kỹ Sư Phần Mềm'),
              const SizedBox(height: 12),
              CustomTextField(controller: salaryCtrl, label: 'Lương Cơ Bản (VNĐ)', hint: '15000000', keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) return;
              final newEmp = EmployeeModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                employeeCode: codeCtrl.text,
                fullName: nameCtrl.text,
                email: emailCtrl.text,
                phone: phoneCtrl.text,
                department: depVal,
                position: posCtrl.text.isEmpty ? 'Nhân Viên' : posCtrl.text,
                baseSalary: double.tryParse(salaryCtrl.text) ?? 15000000,
                avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
                isActive: true,
                joinDate: DateTime.now(),
              );
              await ApiService().addEmployee(newEmp);
              Navigator.pop(ctx);
              _loadAllData();
            },
            child: const Text('Lưu Nhân Sự', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  void _showAddShiftDialog() {
    final nameCtrl = TextEditingController();
    final startCtrl = TextEditingController(text: '08:00');
    final endCtrl = TextEditingController(text: '17:00');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.borderGlass)),
        title: const Text('Thêm Ca Làm Việc', style: TextStyle(color: AppTheme.textWhite, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(controller: nameCtrl, label: 'Tên Ca Làm', hint: 'Ca Sáng / Ca Đêm'),
            const SizedBox(height: 12),
            CustomTextField(controller: startCtrl, label: 'Giờ Bắt Đầu', hint: '08:00'),
            const SizedBox(height: 12),
            CustomTextField(controller: endCtrl, label: 'Giờ Kết Thúc', hint: '17:00'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                ApiService().addWorkShift(nameCtrl.text, startCtrl.text, endCtrl.text);
                Navigator.pop(ctx);
                _loadAllData();
              }
            },
            child: const Text('Tạo Ca Làm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  void _showAddQrDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController(text: 'QR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');
    final locCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.borderGlass)),
        title: const Text('Tạo Mã QR Điểm Danh Mới', style: TextStyle(color: AppTheme.textWhite, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(controller: nameCtrl, label: 'Tên Mã QR', hint: 'QR Sảnh Tầng 1'),
            const SizedBox(height: 12),
            CustomTextField(controller: codeCtrl, label: 'Mã Code QR', hint: 'QR-CODE-2024'),
            const SizedBox(height: 12),
            CustomTextField(controller: locCtrl, label: 'Vị Trí Đặt Mã', hint: 'Cửa Chính Tòa Nhà Landmark'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                ApiService().createQrCode(nameCtrl.text, codeCtrl.text, locCtrl.text);
                Navigator.pop(ctx);
                _loadAllData();
              }
            },
            child: const Text('Tạo Mã QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCard,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: AppTheme.secondary),
            SizedBox(width: 10),
            Text('Trung Tâm Quản Trị Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.secondary,
          labelColor: AppTheme.secondary,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.people_alt_rounded), text: 'Nhân Sự'),
            Tab(icon: Icon(Icons.fact_check_rounded), text: 'Chấm Công'),
            Tab(icon: Icon(Icons.schedule_rounded), text: 'Ca Làm'),
            Tab(icon: Icon(Icons.qr_code_2_rounded), text: 'Mã QR'),
            Tab(icon: Icon(Icons.security_rounded), text: 'Tài Khoản'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEmployeeTab(),
                _buildAttendanceTab(),
                _buildShiftsTab(),
                _buildQrTab(),
                _buildAccountsTab(),
              ],
            ),
    );
  }

  // ================= TAB 1: NHÂN SỰ =================
  Widget _buildEmployeeTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        onPressed: _showAddEmployeeDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm Nhân Sự', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Tìm Kiếm Nhân Sự',
                    hint: 'Tìm theo tên, mã NV, email...',
                    prefixIcon: Icons.search,
                    onChanged: (val) {
                      _employeeSearch = val;
                      _applyEmployeeFilter();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedDepFilter,
                  dropdownColor: AppTheme.bgCard,
                  style: const TextStyle(color: AppTheme.textWhite, fontSize: 12),
                  items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedDepFilter = val);
                      _applyEmployeeFilter();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filteredEmployees.isEmpty
                  ? const Center(child: Text('Không tìm thấy nhân viên', style: TextStyle(color: AppTheme.textMuted)))
                  : ListView.builder(
                      itemCount: _filteredEmployees.length,
                      itemBuilder: (context, idx) {
                        final emp = _filteredEmployees[idx];
                        return GlassCard(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppTheme.primary.withOpacity(0.3),
                                child: Text(
                                  emp.fullName.isNotEmpty ? emp.fullName[0].toUpperCase() : 'N',
                                  style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(emp.fullName, style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 2),
                                    Text('${emp.employeeCode} • ${emp.position}', style: const TextStyle(color: AppTheme.secondary, fontSize: 12)),
                                    const SizedBox(height: 2),
                                    Text('${emp.department} • Lương: ${currencyFormatter.format(emp.baseSalary)}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                                onPressed: () async {
                                  await ApiService().deleteEmployee(emp.id);
                                  _loadAllData();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TAB 2: CHẤM CÔNG =================
  Widget _buildAttendanceTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tổng Điểm Danh', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text('${_attendanceLogs.length} Lượt', style: const TextStyle(color: AppTheme.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tin Cậy Cảm Biến AI', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      SizedBox(height: 4),
                      Text('99.8% Chuẩn', style: TextStyle(color: AppTheme.success, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Nhật Ký Chấm Công Toàn Bộ Nhân Sự', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _attendanceLogs.length,
              itemBuilder: (context, idx) {
                final att = _attendanceLogs[idx];
                return GlassCard(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(att.employeeName, style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 15)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                            child: const Text('Hợp lệ (AI OK)', style: TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${att.department} • Giờ vào: ${DateFormat('HH:mm - dd/MM/yyyy').format(att.checkInTime)}', style: const TextStyle(color: AppTheme.secondary, fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: AppTheme.textMuted, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              att.locationAddress.isNotEmpty ? att.locationAddress : 'GPS: ${att.latitude}, ${att.longitude}',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Thông số AI: Âm thanh ${att.noiseDb} dB | Chuyển động ${att.motionScore} m/s² | Áp suất ${att.pressureHpa} hPa', style: const TextStyle(color: AppTheme.accentGold, fontSize: 10)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAB 3: CA LÀM VIỆC =================
  Widget _buildShiftsTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        onPressed: _showAddShiftDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tạo Ca Mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: _shifts.length,
          itemBuilder: (context, idx) {
            final shift = _shifts[idx];
            return GlassCard(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.secondary.withOpacity(0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.access_time_filled_rounded, color: AppTheme.secondary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(shift['name'], style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('Thời gian: ${shift['startTime']} - ${shift['endTime']}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                    onPressed: () {
                      ApiService().deleteWorkShift(shift['id']);
                      _loadAllData();
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAddAccountDialog() {
    final emailCtrl = TextEditingController();
    String roleVal = 'Admin';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.borderGlass)),
          title: const Text('Tạo Tài Khoản Mới', style: TextStyle(color: AppTheme.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(controller: emailCtrl, label: 'Email Tài Khoản', hint: 'admin@company.com', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: roleVal,
                dropdownColor: AppTheme.bgCard,
                style: const TextStyle(color: AppTheme.textWhite),
                decoration: InputDecoration(
                  labelText: 'Phân Quyền',
                  filled: true,
                  fillColor: AppTheme.bgCardLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Admin', child: Text('Admin (Quản Trị)')),
                  DropdownMenuItem(value: 'Nhân Viên', child: Text('Nhân Viên')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => roleVal = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: AppTheme.textMuted))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (emailCtrl.text.isNotEmpty) {
                  ApiService().createUserAccount(emailCtrl.text.trim(), roleVal);
                  Navigator.pop(ctx);
                  _loadAllData();
                }
              },
              child: const Text('Tạo Tài Khoản', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TAB 4: MÃ QR ĐIỂM DANH =================
  Widget _buildQrTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        onPressed: _showAddQrDialog,
        icon: const Icon(Icons.qr_code, color: Colors.white),
        label: const Text('Tạo Mã QR Mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: _qrCodes.length,
          itemBuilder: (context, idx) {
            final qr = _qrCodes[idx];
            return GlassCard(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.primaryGlow.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.qr_code_2_rounded, color: AppTheme.primaryGlow, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(qr['name'], style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 3),
                        Text('Code: ${qr['code']}', style: const TextStyle(color: AppTheme.secondary, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('Vị trí: ${qr['location']}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                    onPressed: () {
                      ApiService().deleteQrCode(qr['id']);
                      _loadAllData();
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ================= TAB 5: TÀI KHOẢN HỆ THỐNG =================
  Widget _buildAccountsTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        onPressed: _showAddAccountDialog,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Tạo Tài Khoản', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Danh Sách Tài Khoản & Phân Quyền', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          const Text('Admin tạo tài khoản riêng. Nhân viên tự đăng ký và xác thực qua Email.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.builder(
              itemCount: _userAccounts.length,
              itemBuilder: (context, idx) {
                final acc = _userAccounts[idx];
                final isAdmin = acc['role'] == 'Admin';
                final isActive = acc['isActive'] ?? true;

                return GlassCard(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(isAdmin ? Icons.shield_rounded : Icons.person_rounded, color: isAdmin ? AppTheme.accentGold : AppTheme.secondary, size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(acc['email'], style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: (isAdmin ? AppTheme.accentGold : AppTheme.secondary).withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                  child: Text(acc['role'], style: TextStyle(color: isAdmin ? AppTheme.accentGold : AppTheme.secondary, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                  child: const Text('Email Đã Xác Thực', style: TextStyle(color: AppTheme.success, fontSize: 10)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isActive,
                        activeColor: AppTheme.secondary,
                        onChanged: isAdmin ? null : (_) {
                          ApiService().toggleUserStatus(acc['id']);
                          _loadAllData();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
    );
  }
}
