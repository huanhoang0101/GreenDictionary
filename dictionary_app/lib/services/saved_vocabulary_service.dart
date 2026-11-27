import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SavedVocabularyService {
  static SupabaseClient get _client => SupabaseConfig.client;

  static String get _userId {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Vui lòng đăng nhập để quản lý dữ liệu đã lưu.');
    }

    return user.id;
  }

  // Tạo khóa riêng cho từng loại dữ liệu.
  // Ví dụ: jmdict:123 hoặc openjlpt:123
  static String _createItemKey({
    required dynamic itemId,
    required String itemType,
  }) {
    if (itemId == null) {
      throw Exception('Dữ liệu không có ID hợp lệ.');
    }

    return '$itemType:$itemId';
  }

  // Lưu một mục vào các nhóm được chọn.
  static Future<void> saveItem({
    required Map<String, dynamic> item,
    required String itemType,
    required List<String> groupIds,
  }) async {
    final userId = _userId;

    if (groupIds.isEmpty) {
      throw Exception('Vui lòng chọn ít nhất một nhóm.');
    }

    final itemKey = _createItemKey(
      itemId: item['id'],
      itemType: itemType,
    );

    final itemData = Map<String, dynamic>.from(item);

    if (itemType == 'openjlpt') {
      itemData['type'] = 'grammar';
    }

    final savedItem = await _client
        .from('saved_vocabulary')
        .upsert({
          'user_id': userId,
          'word_key': itemKey,
          'word_data': itemData,
        }, onConflict: 'user_id,word_key')
        .select('id')
        .single();

    final savedItemId = savedItem['id'].toString();

    final links = groupIds.map((groupId) {
      return {
        'group_id': groupId,
        'saved_word_id': savedItemId,
      };
    }).toList();

    await _client.from('vocabulary_group_words').upsert(
      links,
      onConflict: 'group_id,saved_word_id',
      ignoreDuplicates: true,
    );
  }

  // Cập nhật danh sách nhóm của một mục đã lưu.
  // Nếu không còn nhóm nào, mục đó sẽ bị xóa khỏi danh sách đã lưu.
  static Future<void> updateItemGroups({
    required Map<String, dynamic> item,
    required String itemType,
    required List<String> groupIds,
  }) async {
    final userId = _userId;

    final itemKey = _createItemKey(
      itemId: item['id'],
      itemType: itemType,
    );

    final itemData = Map<String, dynamic>.from(item);

    if (itemType == 'openjlpt') {
      itemData['type'] = 'grammar';
    }

    var savedItem = await _client
        .from('saved_vocabulary')
        .select('id')
        .eq('user_id', userId)
        .eq('word_key', itemKey)
        .maybeSingle();

    // Chưa từng lưu và không chọn nhóm nào thì không cần làm gì.
    if (savedItem == null && groupIds.isEmpty) {
      return;
    }

    // Chưa từng lưu nhưng đã chọn nhóm thì tạo bản ghi.
    if (savedItem == null) {
      savedItem = await _client
          .from('saved_vocabulary')
          .insert({
            'user_id': userId,
            'word_key': itemKey,
            'word_data': itemData,
          })
          .select('id')
          .single();
    } else {
      // Cập nhật dữ liệu mới nhất nếu mục đã tồn tại.
      await _client
          .from('saved_vocabulary')
          .update({'word_data': itemData})
          .eq('id', savedItem['id'])
          .eq('user_id', userId);
    }

    final savedItemId = savedItem['id'].toString();

    final currentLinks = await _client
        .from('vocabulary_group_words')
        .select('group_id')
        .eq('saved_word_id', savedItemId);

    final currentIds = currentLinks
        .map<String>((item) => item['group_id'].toString())
        .toSet();

    final newIds = groupIds.toSet();

    final idsToAdd = newIds.difference(currentIds);
    final idsToRemove = currentIds.difference(newIds);

    if (idsToAdd.isNotEmpty) {
      await _client.from('vocabulary_group_words').insert(
        idsToAdd.map((groupId) {
          return {
            'group_id': groupId,
            'saved_word_id': savedItemId,
          };
        }).toList(),
      );
    }

    if (idsToRemove.isNotEmpty) {
      await _client
          .from('vocabulary_group_words')
          .delete()
          .eq('saved_word_id', savedItemId)
          .inFilter('group_id', idsToRemove.toList());
    }

    // Nếu không còn nhóm nào, xóa mục khỏi danh sách đã lưu.
    if (newIds.isEmpty) {
      await _client
          .from('saved_vocabulary')
          .delete()
          .eq('id', savedItemId)
          .eq('user_id', userId);
    }
  }

  // Lấy các nhóm mà một mục đã được lưu vào.
  static Future<List<String>> getSavedGroupIdsForItem({
    required dynamic itemId,
    required String itemType,
  }) async {
    final userId = _userId;

    final itemKey = _createItemKey(
      itemId: itemId,
      itemType: itemType,
    );

    final response = await _client
        .from('saved_vocabulary')
        .select('vocabulary_group_words(group_id)')
        .eq('user_id', userId)
        .eq('word_key', itemKey)
        .maybeSingle();

    if (response == null) return [];

    final links =
        response['vocabulary_group_words'] as List<dynamic>? ?? [];

    return links
        .map<String>((item) => item['group_id'].toString())
        .toList();
  }

  // Lấy tất cả mục đã lưu, gồm cả từ vựng và ngữ pháp.
  static Future<List<Map<String, dynamic>>> getAllSavedItems() async {
    final userId = _userId;

    final response = await _client
        .from('saved_vocabulary')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Lấy tất cả mục trong một nhóm.
  static Future<List<Map<String, dynamic>>> getItemsInGroup(
    String groupId,
  ) async {
    final userId = _userId;

    final response = await _client
        .from('saved_vocabulary')
        .select('*, vocabulary_group_words!inner(group_id)')
        .eq('user_id', userId)
        .eq('vocabulary_group_words.group_id', groupId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Kiểm tra một mục đã được lưu hay chưa.
  static Future<bool> isItemSaved({
    required dynamic itemId,
    required String itemType,
  }) async {
    final userId = _userId;

    final itemKey = _createItemKey(
      itemId: itemId,
      itemType: itemType,
    );

    final result = await _client
        .from('saved_vocabulary')
        .select('id')
        .eq('user_id', userId)
        .eq('word_key', itemKey)
        .maybeSingle();

    return result != null;
  }

  // Gỡ một mục khỏi một nhóm.
  // Nếu mục không còn thuộc nhóm nào, xóa luôn mục đã lưu.
  static Future<void> removeItemFromGroup({
    required String groupId,
    required String savedItemId,
  }) async {
    final userId = _userId;

    await _client
        .from('vocabulary_group_words')
        .delete()
        .eq('group_id', groupId)
        .eq('saved_word_id', savedItemId);

    final remainingLinks = await _client
        .from('vocabulary_group_words')
        .select('group_id')
        .eq('saved_word_id', savedItemId);

    if (remainingLinks.isEmpty) {
      await _client
          .from('saved_vocabulary')
          .delete()
          .eq('id', savedItemId)
          .eq('user_id', userId);
    }
  }

  // --------------------------------------------------
  // Các hàm cũ dành cho từ vựng.
  // Giữ lại để những màn hình hiện tại tiếp tục hoạt động.
  // --------------------------------------------------

  static Future<void> saveWord({
    required Map<String, dynamic> word,
    required List<String> groupIds,
  }) {
    return saveItem(
      item: word,
      itemType: 'jmdict',
      groupIds: groupIds,
    );
  }

  static Future<void> updateWordGroups({
    required Map<String, dynamic> word,
    required List<String> groupIds,
  }) {
    return updateItemGroups(
      item: word,
      itemType: 'jmdict',
      groupIds: groupIds,
    );
  }

  static Future<List<Map<String, dynamic>>> getAllSavedWords() {
    return getAllSavedItems();
  }

  static Future<List<Map<String, dynamic>>> getWordsInGroup(
    String groupId,
  ) {
    return getItemsInGroup(groupId);
  }

  static Future<List<String>> getSavedGroupIds({
    required dynamic wordId,
  }) {
    return getSavedGroupIdsForItem(
      itemId: wordId,
      itemType: 'jmdict',
    );
  }

  static Future<bool> isWordSaved(dynamic wordId) {
    return isItemSaved(
      itemId: wordId,
      itemType: 'jmdict',
    );
  }

  static Future<void> removeSavedWord(String savedWordId) async {
    final userId = _userId;

    await _client
        .from('saved_vocabulary')
        .delete()
        .eq('id', savedWordId)
        .eq('user_id', userId);
  }

  static Future<void> removeWordFromGroup({
    required String groupId,
    required String savedWordId,
  }) {
    return removeItemFromGroup(
      groupId: groupId,
      savedItemId: savedWordId,
    );
  }
}