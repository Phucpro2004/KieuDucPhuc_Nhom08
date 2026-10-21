import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_text_field.dart';
import '../../models/employee_model.dart';
import '../../services/api_service.dart';

class EmployeeCrudScreen extends StatefulWidget {
  const EmployeeCrudScreen({super.key});

  @override
  State<EmployeeCrudScreen> createState() => _EmployeeCrudScreenState();
}

class _EmployeeCrudScreenState extends State<EmployeeCrudScreen> {
  List<EmployeeModel> _employees = [];
  List<EmployeeModel> _filteredEmployees = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'Tất cả';

  final List<String> _categories = [
    'Tất cả',
    'Ban Giám Đốc',
    'Phòng Công Nghệ',
    'Phòng Nhân Sự',
    'Phòng Tài Chính',
  ];

  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  void _loadEmployees() async {
    setState(() => _isLoading = true);
    final data = await ApiService().getEmployees();
    setState(() {
      _employees = data;
      _applyFilter();
      _isLoading = false;
    });
  }

  void _applyFilter() {
    setState(() {
      _filteredEmployees = _employees.where((emp) {
        bool matchesCategory = _selectedCategory == 'Tất cả' || emp.department == _selectedCategory;
        bool matchesQuery = emp.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            emp.employeeCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            emp.email.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesCategory && matchesQuery;
      }).toList();
    });
  }

  void _showAddEditModal({EmployeeModel? employeeToEdit}) {
    final isEdit = employeeToEdit != null;
    final codeController = TextEditingController(text: isEdit ? employeeToEdit.employeeCode : 'NV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final nameController = TextEditingController(text: isEdit ? employeeToEdit.fullName : '');
    final emailController = TextEditingController(text: isEdit ? employeeToEdit.email : '');
    final phoneController = TextEditingController(text: isEdit ? employeeToEdit.phone : '');
    final positionController = TextEditingController(text: isEdit ? employeeToEdit.position : 'Chuyên viên');
    final salaryController = TextEditingController(text: isEdit ? employeeToEdit.baseSalary.toStringAsFixed(0) : '18000000');
    String department = isEdit ? employeeToEdit.department : 'Phòng Công Nghệ';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: GlassCard(
                borderRadius: 24,
                color: AppTheme.bgCard,
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEdit ? 'Sửa Thông Tin Nhân Viên' : 'Thêm Nhân Viên Mới',
                            style: const TextStyle(color: AppTheme.textWhite, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppTheme.textMuted),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: codeController,
                        label: 'Mã Nhân Viên',
                        hint: 'NV-2024',
                        prefixIcon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: nameController,
                        label: 'Họ và Tên',
                        hint: 'Nguyễn Văn A',
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: emailController,
                        label: 'Email Doanh Nghiệp',
                        hint: 'nv@company.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: phoneController,
                        label: 'Số Điện Thoại',
                        hint: '0912345678',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),

                      // Department Selection
                      const Text('Phòng Ban', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: department,
                        dropdownColor: AppTheme.bgCard,
                        style: const TextStyle(color: AppTheme.textWhite),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppTheme.bgCardLight,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        items: ['Ban Giám Đốc', 'Phòng Công Nghệ', 'Phòng Nhân Sự', 'Phòng Tài Chính', 'Phòng Kinh Doanh'].map((dep) {
                          return DropdownMenuItem(value: dep, child: Text(dep));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => department = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: positionController,
                        label: 'Chức Danh',
                        hint: 'Trưởng phòng / Lập trình viên',
                        prefixIcon: Icons.work_outline,
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: salaryController,
                        label: 'Lương Cơ Bản (VNĐ)',
                        hint: '15000000',
                        prefixIcon: Icons.attach_money_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (nameController.text.isEmpty || emailController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Vui lòng điền đủ Tên và Email!')),
                              );
                              return;
                            }

                            final newEmp = EmployeeModel(
                              id: isEdit ? employeeToEdit.id : DateTime.now().millisecondsSinceEpoch.toString(),
                              employeeCode: codeController.text,
                              fullName: nameController.text,
                              email: emailController.text,
                              phone: phoneController.text,
                              department: department,
                              position: positionController.text,
                              baseSalary: double.tryParse(salaryController.text) ?? 15000000,
                              avatarUrl: isEdit ? employeeToEdit.avatarUrl : 'https://i.pravatar.cc/150?img=${DateTime.now().second}',
                              isActive: isEdit ? employeeToEdit.isActive : true,
                              joinDate: isEdit ? employeeToEdit.joinDate : DateTime.now(),
                            );

                            if (isEdit) {
                              await ApiService().updateEmployee(newEmp);
                            } else {
                              await ApiService().addEmployee(newEmp);
                            }

                            Navigator.pop(context);
                            _loadEmployees();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppTheme.success,
                                content: Text(isEdit ? 'Cập nhật nhân viên thành công!' : 'Thêm nhân viên mới thành công!'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            isEdit ? 'LƯU THAY ĐỔI' : 'TẠO HỒ SƠ NHÂN VIÊN',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(EmployeeModel employee) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 28),
              SizedBox(width: 10),
              Text('Xác Nhận Xóa', style: TextStyle(color: AppTheme.textWhite, fontSize: 18)),
            ],
          ),
          content: Text(
            'Bạn có chắc chắn muốn xóa hồ sơ nhân viên "${employee.fullName}" (${employee.employeeCode}) ra khỏi hệ thống?',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                await ApiService().deleteEmployee(employee.id);
                Navigator.pop(context);
                _loadEmployees();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppTheme.error,
                    content: Text('Đã xóa nhân viên khỏi cơ sở dữ liệu!'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
              child: const Text('XÓA NGAY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Quản Lý Hồ Sơ Nhân Sự (CRUD)'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditModal(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text('Thêm Nhân Viên', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppTheme.bgDark,
        child: SafeArea(
          child: Column(
            children: [
              // Search & Category Filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    TextField(
                      style: const TextStyle(color: AppTheme.textWhite),
                      decoration: InputDecoration(
                        hintText: 'Tìm theo Tên, Mã NV, Email...',
                        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.secondary),
                        filled: true,
                        fillColor: AppTheme.bgCard,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) {
                        _searchQuery = val;
                        _applyFilter();
                      },
                    ),
                    const SizedBox(height: 12),

                    // Categories horizontal bar
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              selectedColor: AppTheme.primary,
                              backgroundColor: AppTheme.bgCard,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.textMuted,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                              onSelected: (_) {
                                setState(() => _selectedCategory = cat);
                                _applyFilter();
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Employee List View
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                    : _filteredEmployees.isEmpty
                        ? const Center(
                            child: Text('Không tìm thấy nhân viên nào', style: TextStyle(color: AppTheme.textMuted)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            itemCount: _filteredEmployees.length,
                            itemBuilder: (context, index) {
                              final emp = _filteredEmployees[index];
                              return GlassCard(
                                margin: const EdgeInsets.only(bottom: 14),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 26,
                                          backgroundImage: NetworkImage(emp.avatarUrl),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    emp.fullName,
                                                    style: const TextStyle(
                                                      color: AppTheme.textWhite,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.secondary.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      emp.employeeCode,
                                                      style: const TextStyle(color: AppTheme.secondary, fontSize: 10, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${emp.position} • ${emp.department}',
                                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Lương: ${currencyFormatter.format(emp.baseSalary)}',
                                                style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.w600, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMuted),
                                          color: AppTheme.bgCard,
                                          onSelected: (action) {
                                            if (action == 'edit') {
                                              _showAddEditModal(employeeToEdit: emp);
                                            } else if (action == 'delete') {
                                              _confirmDelete(emp);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit_outlined, color: AppTheme.secondary, size: 20),
                                                  SizedBox(width: 8),
                                                  Text('Chỉnh Sửa', style: TextStyle(color: AppTheme.textWhite)),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                                                  SizedBox(width: 8),
                                                  Text('Xóa Hồ Sơ', style: TextStyle(color: AppTheme.error)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
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
      ),
    );
  }
}
