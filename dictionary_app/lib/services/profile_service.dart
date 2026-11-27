import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class ProfileService {
  static final _client = SupabaseConfig.client;

  // Lấy hồ sơ người dùng hiện tại
  static Future<Map<String, dynamic>> getProfile() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return response;
  }

  // Cập nhật tên người dùng
  static Future<void> updateFullName(String fullName) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    await _client
        .from('profiles')
        .update({
          'full_name': fullName.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', user.id);

    // Đồng bộ tên trong metadata của Supabase Auth
    await _client.auth.updateUser(
      UserAttributes(
        data: {'full_name': fullName.trim()},
      ),
    );
  }


  // Tải ảnh đại diện lên Supabase Storage
  static Future<String> uploadAvatar(Uint8List imageBytes) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    final filePath =
        '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _client.storage.from('avatars').uploadBinary(
      filePath,
      imageBytes,
      fileOptions: const FileOptions(
        contentType: 'image/jpeg',
      ),
    );

    final imageUrl =
        _client.storage.from('avatars').getPublicUrl(filePath);

    await _client
        .from('profiles')
        .update({
          'avatar_url': imageUrl,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', user.id);

    return imageUrl;
  }

}
