import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/api_service.dart';

class GroupVideoCallScreen extends StatefulWidget {
  const GroupVideoCallScreen({super.key});

  @override
  State<GroupVideoCallScreen> createState() => _GroupVideoCallScreenState();
}

class _GroupVideoCallScreenState extends State<GroupVideoCallScreen> with SingleTickerProviderStateMixin {
  // Trạng thái cuộc gọi
  bool _isInCall = false;
  String _currentMeetingCode = '';
  String _currentMeetingLink = '';

  // Điều khiển Camera & Mic
  bool _isMuted = false;
  bool _isVideoOn = true;
  bool _isFrontCamera = true;
  bool _isSpeakerOn = true;
  bool _isHandRaised = false;

  // Lịch sử cuộc họp đã tạo / tham gia
  final List<Map<String, String>> _recentMeetings = [
    {
      'code': 'kdp-hr8-meet',
      'link': 'https://meet.google.com/kdp-hr8-meet',
      'title': 'Họp Giao Ban Dự Án Nhóm 8',
      'time': 'Hôm nay, 08:30',
    },
    {
      'code': 'corp-tech-sync',
      'link': 'https://meet.google.com/corp-tech-sync',
      'title': 'Đồng Bộ Kỹ Thuật & Cảm Biến AI',
      'time': 'Hôm qua, 14:15',
    },
  ];

  // Tin nhắn trong cuộc họp (In-call messages)
  final List<Map<String, String>> _chatMessages = [
    {'sender': 'Hệ thống', 'text': 'Cuộc họp được mã hóa bảo mật cấp cao.', 'time': 'Bây giờ'},
  ];
  final TextEditingController _chatController = TextEditingController();

  // Danh sách thành viên cùng tham gia trong phòng họp
  final List<Map<String, dynamic>> _callParticipants = [
    {
      'name': 'Kiều Đức Phúc',
      'role': 'Phó Giám Đốc Kỹ Thuật',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      'isMuted': false,
      'isVideoOn': true,
      'isSpeaking': true,
    },
    {
      'name': 'Trần Thu Hà',
      'role': 'Trưởng Ban Kiểm Soát AI',
      'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      'isMuted': true,
      'isVideoOn': true,
      'isSpeaking': false,
    },
  ];

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  /// Tạo mã cuộc họp ngẫu nhiên chuẩn Google Meet (dạng abc-defg-hij)
  String _generateMeetingCode() {
    const chars = 'abcdefghijklmnopqrstuvwxyz';
    final random = Random();
    String part1 = List.generate(3, (_) => chars[random.nextInt(chars.length)]).join();
    String part2 = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    String part3 = List.generate(3, (_) => chars[random.nextInt(chars.length)]).join();
    return '$part1-$part2-$part3';
  }

  /// Bắt đầu hoặc tham gia cuộc họp
  void _joinMeeting(String code, {String? customTitle}) {
    final cleanCode = code.replaceAll('https://meet.google.com/', '').trim();
    if (cleanCode.isEmpty) return;

    setState(() {
      _currentMeetingCode = cleanCode;
      _currentMeetingLink = 'https://meet.google.com/$cleanCode';
      _isInCall = true;
      _isMuted = false;
      _isVideoOn = true;
      _isHandRaised = false;

      // Lưu vào danh sách cuộc họp gần đây nếu chưa có
      if (!_recentMeetings.any((m) => m['code'] == cleanCode)) {
        _recentMeetings.insert(0, {
          'code': cleanCode,
          'link': _currentMeetingLink,
          'title': customTitle ?? 'Cuộc Họp Trực Tuyến ($cleanCode)',
          'time': 'Vừa xong',
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.success,
        content: Text('Đã kết nối vào phòng họp Google Meet: $cleanCode'),
      ),
    );
  }

  /// Rời khỏi cuộc họp và quay lại sảnh Google Meet
  void _leaveMeeting() {
    setState(() {
      _isInCall = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bạn đã rời khỏi cuộc họp.'),
      ),
    );
  }

  /// Modal tạo cuộc họp mới phong cách Google Meet
  void _showNewMeetingBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppTheme.textMuted.withOpacity(0.4), borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bắt Đầu Cuộc Họp Mới',
                  style: TextStyle(color: AppTheme.textWhite, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Lựa chọn 1: Bắt đầu cuộc họp tức thì
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.bolt_rounded, color: AppTheme.primary, size: 24),
                  ),
                  title: const Text('Bắt đầu cuộc họp tức thì', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: const Text('Tạo phòng họp trực tuyến và kết nối ngay', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    final newCode = _generateMeetingCode();
                    _joinMeeting(newCode, customTitle: 'Cuộc Họp Tức Thì ($newCode)');
                  },
                ),
                const Divider(color: AppTheme.borderGlass, height: 16),

                // Lựa chọn 2: Tạo cuộc họp để sử dụng sau
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.secondary.withOpacity(0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.link_rounded, color: AppTheme.secondary, size: 24),
                  ),
                  title: const Text('Tạo cuộc họp để sử dụng sau', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: const Text('Nhận đường liên kết mời tham gia để gửi cho đồng nghiệp', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    final newCode = _generateMeetingCode();
                    _showCreatedLinkDialog(newCode);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Hộp thoại hiển thị liên kết cuộc họp vừa tạo để copy hoặc chia sẻ
  void _showCreatedLinkDialog(String code) {
    final link = 'https://meet.google.com/$code';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.borderGlass)),
        title: const Row(
          children: [
            Icon(Icons.video_call_rounded, color: AppTheme.secondary, size: 26),
            SizedBox(width: 10),
            Text('Đây Là Đường Liên Kết Cuộc Họp', style: TextStyle(color: AppTheme.textWhite, fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gửi đường liên kết này cho những người bạn muốn họ tham gia cuộc họp:',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.bgCardLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderGlass),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      link,
                      style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
                    tooltip: 'Sao chép',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: link));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppTheme.success,
                          content: Text('Đã sao chép đường liên kết cuộc họp vào bộ nhớ tạm!'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Để Sau', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _joinMeeting(code, customTitle: 'Cuộc Họp Đã Lưu ($code)');
            },
            child: const Text('Tham Gia Ngay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Hộp thoại tham gia bằng mã hoặc liên kết
  void _showJoinWithCodeDialog() {
    final codeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.borderGlass)),
        title: const Text('Tham Gia Bằng Mã Hoặc Liên Kết', style: TextStyle(color: AppTheme.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập mã cuộc họp do người tổ chức cung cấp (ví dụ: abc-defg-hij):',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: codeCtrl,
              label: 'Mã hoặc liên kết Google Meet',
              hint: 'nhom8-exec-2024',
              prefixIcon: Icons.keyboard_rounded,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            onPressed: () {
              if (codeCtrl.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                _joinMeeting(codeCtrl.text.trim());
              }
            },
            child: const Text('Tham Gia', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Mở khung trò chuyện trong cuộc họp
  void _showInCallChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setChatState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: 380,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tin Nhắn Trong Cuộc Họp', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(color: AppTheme.borderGlass),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _chatMessages.length,
                        itemBuilder: (context, idx) {
                          final msg = _chatMessages[idx];
                          final isMe = msg['sender'] == 'Bạn';
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isMe ? AppTheme.primary.withOpacity(0.3) : AppTheme.bgCardLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isMe ? AppTheme.primary : AppTheme.borderGlass),
                              ),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(msg['sender']!, style: TextStyle(color: isMe ? AppTheme.secondary : AppTheme.accentGold, fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(msg['text']!, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Gửi tin nhắn cho mọi người...',
                              hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                              filled: true,
                              fillColor: AppTheme.bgCardLight,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: AppTheme.primary,
                          child: IconButton(
                            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                            onPressed: () {
                              if (_chatController.text.trim().isNotEmpty) {
                                final text = _chatController.text.trim();
                                setChatState(() {
                                  _chatMessages.add({'sender': 'Bạn', 'text': text, 'time': 'Bây giờ'});
                                  _chatController.clear();
                                });
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInCall) {
      return _buildMeetingRoom();
    }
    return _buildLobbyScreen();
  }

  // ================= 1. MÀN HÌNH SẢNH CHỜ GOOGLE MEET (LOBBY) =================
  Widget _buildLobbyScreen() {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.video_camera_front_rounded, color: AppTheme.secondary, size: 26),
            SizedBox(width: 10),
            Text('Họp Video Bảo Mật', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner
              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.diversity_3_rounded, color: AppTheme.secondary, size: 36),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hội Họp Nhóm Trực Tuyến', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 4),
                          Text('Chuẩn phong cách Google Meet: tạo cuộc họp tức thì, chia sẻ liên kết, dùng micro và camera trực tiếp.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.3)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2 Nút Chính: Cuộc Họp Mới & Tham Gia Bằng Mã
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showNewMeetingBottomSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.video_call_rounded, color: Colors.white, size: 22),
                      label: const Text('Cuộc Họp Mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showJoinWithCodeDialog,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.secondary, width: 1.5),
                        foregroundColor: AppTheme.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.keyboard_rounded, size: 20),
                      label: const Text('Dùng Mã / Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Danh sách cuộc họp gần đây
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cuộc Họp Gần Đây & Đã Lưu', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${_recentMeetings.length} phòng', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentMeetings.length,
                itemBuilder: (context, idx) {
                  final meeting = _recentMeetings[idx];
                  return GlassCard(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppTheme.bgCardLight, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.meeting_room_rounded, color: AppTheme.secondary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(meeting['title']!, style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 3),
                              Text('Mã: ${meeting['code']}', style: const TextStyle(color: AppTheme.secondary, fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(meeting['time']!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, color: AppTheme.textMuted, size: 18),
                          tooltip: 'Sao chép liên kết',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: meeting['link']!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Đã sao chép liên kết: ${meeting['link']}')),
                            );
                          },
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _joinMeeting(meeting['code']!, customTitle: meeting['title']),
                          child: const Text('Vào Họp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),
              // Security info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.bgCardLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderGlass),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_rounded, color: AppTheme.accentGold, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cuộc họp của bạn được bảo mật tuyệt đối với mã hóa đầu cuối và xác thực danh tính AI.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= 2. GIAO DIỆN PHÒNG HỌP GOOGLE MEET (IN-MEETING ROOM) =================
  Widget _buildMeetingRoom() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Meeting Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.black.withOpacity(0.7),
              child: Row(
                children: [
                  // Meeting Code Chip (Tap to Copy Link)
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _currentMeetingLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppTheme.success,
                          content: Text('Đã sao chép liên kết mời: $_currentMeetingLink'),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCardLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderGlass),
                      ),
                      child: Row(
                        children: [
                          Text(_currentMeetingCode, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 6),
                          const Icon(Icons.copy_rounded, color: AppTheme.secondary, size: 14),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Switch Front/Back Camera
                  IconButton(
                    icon: Icon(_isFrontCamera ? Icons.cameraswitch_rounded : Icons.camera_rear_rounded, color: Colors.white),
                    tooltip: 'Chuyển Camera Trước/Sau',
                    onPressed: () {
                      setState(() => _isFrontCamera = !_isFrontCamera);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 1),
                          content: Text(_isFrontCamera ? 'Đã chuyển sang Camera trước' : 'Đã chuyển sang Camera sau'),
                        ),
                      );
                    },
                  ),

                  // Toggle Speaker
                  IconButton(
                    icon: Icon(_isSpeakerOn ? Icons.volume_up_rounded : Icons.hearing_rounded, color: Colors.white),
                    tooltip: 'Bật/Tắt Loa Ngoài',
                    onPressed: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                  ),

                  // Share meeting invite
                  IconButton(
                    icon: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.secondary),
                    tooltip: 'Mời thành viên',
                    onPressed: () => _showCreatedLinkDialog(_currentMeetingCode),
                  ),
                ],
              ),
            ),

            // Video Tiles Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    // Ô Video Của Bạn (Tôi)
                    Expanded(
                      flex: 1,
                      child: _buildUserVideoTile(),
                    ),
                    const SizedBox(height: 8),

                    // Ô Video Các Thành Viên Khác
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: _callParticipants.map((p) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: _buildParticipantTile(p),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Google Meet Floating Control Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1F22),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, -3)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Nút Bật/Tắt Micro
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: _isMuted ? AppTheme.error : const Color(0xFF3C4043),
                    child: IconButton(
                      icon: Icon(_isMuted ? Icons.mic_off_rounded : Icons.mic_rounded, color: Colors.white),
                      tooltip: _isMuted ? 'Bật Micro' : 'Tắt Micro',
                      onPressed: () {
                        setState(() => _isMuted = !_isMuted);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            duration: const Duration(milliseconds: 900),
                            content: Text(_isMuted ? 'Đã tắt micro' : 'Đã bật micro'),
                          ),
                        );
                      },
                    ),
                  ),

                  // Nút Bật/Tắt Camera
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: !_isVideoOn ? AppTheme.error : const Color(0xFF3C4043),
                    child: IconButton(
                      icon: Icon(!_isVideoOn ? Icons.videocam_off_rounded : Icons.videocam_rounded, color: Colors.white),
                      tooltip: _isVideoOn ? 'Tắt Máy Ảnh' : 'Bật Máy Ảnh',
                      onPressed: () {
                        setState(() => _isVideoOn = !_isVideoOn);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            duration: const Duration(milliseconds: 900),
                            content: Text(_isVideoOn ? 'Đã bật camera máy thật' : 'Đã tắt camera máy thật'),
                          ),
                        );
                      },
                    ),
                  ),

                  // Nút Giơ Tay Phát Biểu
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: _isHandRaised ? AppTheme.accentGold : const Color(0xFF3C4043),
                    child: IconButton(
                      icon: Icon(Icons.front_hand_rounded, color: _isHandRaised ? Colors.black : Colors.white),
                      tooltip: 'Giơ tay phát biểu',
                      onPressed: () {
                        setState(() => _isHandRaised = !_isHandRaised);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            duration: const Duration(seconds: 1),
                            content: Text(_isHandRaised ? 'Bạn đã giơ tay phát biểu' : 'Đã hạ tay xuống'),
                          ),
                        );
                      },
                    ),
                  ),

                  // Nút Trò Chuyện Trong Cuộc Họp
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: const Color(0xFF3C4043),
                    child: IconButton(
                      icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
                      tooltip: 'Trò chuyện trong cuộc họp',
                      onPressed: _showInCallChat,
                    ),
                  ),

                  // Nút Rời Cuộc Họp (Nút đỏ Google Meet đặc trưng)
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: IconButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      icon: const Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
                      tooltip: 'Rời khỏi cuộc họp',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppTheme.bgCard,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('Rời Cuộc Họp?', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                            content: const Text('Bạn có chắc chắn muốn rời khỏi phiên họp này không?', style: TextStyle(color: AppTheme.textMuted)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ở lại', style: TextStyle(color: AppTheme.textMuted))),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _leaveMeeting();
                                },
                                child: const Text('Rời Họp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          ],
        ),
      ),
    );
  }

  /// Ô video của chính người dùng (Bạn)
  Widget _buildUserVideoTile() {
    final user = ApiService().currentUser;
    final userName = user?.fullName ?? 'Bạn (Tôi)';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF202124),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isHandRaised ? AppTheme.accentGold : (!_isMuted ? AppTheme.secondary.withOpacity(0.5) : AppTheme.borderGlass),
          width: _isHandRaised ? 2 : 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Nếu Camera BẬT: Khung camera tương tác trực tiếp
          if (_isVideoOn)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Mô phỏng live camera stream người dùng
                    Image.network(
                      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.6)],
                        ),
                      ),
                    ),
                    // Live camera active watermark
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(_isFrontCamera ? 'Camera Trước (Live)' : 'Camera Sau (Live)', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Nếu Camera TẮT: Avatar Google Meet chuẩn
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'T',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Máy ảnh đã tắt', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),

          // Tên hiển thị & Trạng thái Mic của Bạn
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(width: 6),
                  Icon(
                    _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    color: _isMuted ? AppTheme.error : AppTheme.success,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),

          // Huy hiệu Giơ tay
          if (_isHandRaised)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: AppTheme.accentGold, shape: BoxShape.circle),
                child: const Icon(Icons.front_hand_rounded, color: Colors.black, size: 16),
              ),
            ),
        ],
      ),
    );
  }

  /// Ô video của đồng nghiệp khác trong phòng
  Widget _buildParticipantTile(Map<String, dynamic> p) {
    final bool isSpeaking = p['isSpeaking'] ?? false;
    final bool isMuted = p['isMuted'] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF202124),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSpeaking ? AppTheme.success : AppTheme.borderGlass,
          width: isSpeaking ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              p['avatar']!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              ),
            ),
          ),

          // Speaker wave indicator
          if (isSpeaking)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.success, borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text('Đang nói', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

          // Name tag & Mic status
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(p['role']!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Icon(
                  isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  color: isMuted ? AppTheme.error : AppTheme.success,
                  size: 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
