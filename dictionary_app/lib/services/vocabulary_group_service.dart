import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class VocabularyGroupService {
  static SupabaseClient get _client => SupabaseConfig.client;

  // Lấy danh sách nhóm kèm số mục đã lưu trong từng nhóm.
  static Future<List<Map<String, dynamic>>> getGroups() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Vui lòng đăng nhập để xem nhóm từ vựng.');
    }

    final response = await _client
        .from('vocabulary_groups')
        .select('*, vocabulary_group_words(count)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Tạo nhóm từ vựng mới.
  static Future<Map<String, dynamic>> createGroup({
    required String name,
    String? description,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Vui lòng đăng nhập để tạo nhóm từ vựng.');
    }

    final groupName = name.trim();

    if (groupName.isEmpty) {
      throw Exception('Tên nhóm không được để trống.');
    }

    final response = await _client
        .from('vocabulary_groups')
        .insert({
          'user_id': user.id,
          'name': groupName,
          'description': description?.trim(),
        })
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  // Đổi tên nhóm.
  static Future<void> renameGroup({
    required String groupId,
    required String newName,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Vui lòng đăng nhập để đổi tên nhóm.');
    }

    final groupName = newName.trim();

    if (groupName.isEmpty) {
      throw Exception('Tên nhóm không được để trống.');
    }

    await _client
        .from('vocabulary_groups')
        .update({
          'name': groupName,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', groupId)
        .eq('user_id', user.id);
  }

  // Xóa nhóm từ vựng.
  static Future<void> deleteGroup(String groupId) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Vui lòng đăng nhập để xóa nhóm từ vựng.');
    }

    await _client
        .from('vocabulary_groups')
        .delete()
        .eq('id', groupId)
        .eq('user_id', user.id);
  }
}