import 'package:flutter/material.dart';

import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../services/profile_service.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _uploadingAvatar = false;

  bool _loading = true;
  bool _saving = false;
  String? _email;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Tải thông tin hồ sơ
  Future<void> _loadProfile() async {
    try {
      final user = AuthService.currentUser;

      if (user == null) {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
        return;
      }

      final profile = await ProfileService.getProfile();

      if (!mounted) return;

      setState(() {
        _email = user.email;
        _nameController.text = profile['full_name'] ?? '';
        _avatarUrl = profile['avatar_url'];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không thể tải hồ sơ: $error')));
    }
  }

  // Lưu tên người dùng
  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập họ và tên.')));
      return;
    }

    setState(() => _saving = true);

    try {
      await ProfileService.updateFullName(name);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật hồ sơ thành công!')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Cập nhật thất bại: $error')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image == null) return;

      setState(() => _uploadingAvatar = true);

      final Uint8List imageBytes = await image.readAsBytes();

      final imageUrl = await ProfileService.uploadAvatar(imageBytes);

      if (!mounted) return;

      setState(() {
        _avatarUrl = imageUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật ảnh đại diện thành công!')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể tải ảnh lên: $error')));
    } finally {
      if (mounted) {
        setState(() => _uploadingAvatar = false);
      }
    }
  }

  // Đăng xuất
  Future<void> _logout() async {
    try {
      await AuthService.signOut();

      if (!mounted) return;

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đăng xuất thất bại.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF263238),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF35A995)),
            )
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Thông tin tài khoản',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF263238),
                            ),
                          ),

                          const SizedBox(height: 28),

                          Center(
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 48,
                                  backgroundColor: const Color(0xFFE4F5F1),
                                  backgroundImage:
                                      _avatarUrl != null &&
                                          _avatarUrl!.isNotEmpty
                                      ? NetworkImage(_avatarUrl!)
                                      : null,
                                  child:
                                      _avatarUrl == null || _avatarUrl!.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          size: 52,
                                          color: Color(0xFF35A995),
                                        )
                                      : null,
                                ),
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF35A995),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    onPressed: _uploadingAvatar
                                        ? null
                                        : _pickAvatar,
                                    icon: _uploadingAvatar
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          const Text(
                            'Email',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),

                          TextFormField(
                            initialValue: _email ?? '',
                            readOnly: true,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.email_outlined),
                              filled: true,
                              fillColor: const Color(0xFFF3F5F6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            'Họ và tên',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),

                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.person_outline),
                              hintText: 'Nhập họ và tên',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF35A995),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _saving
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text('Lưu thay đổi'),
                            ),
                          ),

                          const SizedBox(height: 12),

                          OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout),
                            label: const Text('Đăng xuất'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
