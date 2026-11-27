
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class GrammarService {
  static String get baseUrl => ApiConfig.baseUrl;

  /// Tìm kiếm ngữ pháp và lọc theo cấp độ JLPT
  Future<Map<String, dynamic>> search({
    String query = '',
    String? level,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParameters = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    if (query.trim().isNotEmpty) {
      queryParameters['q'] = query.trim();
    }

    if (level != null && level.isNotEmpty) {
      queryParameters['level'] = level;
    }

    final uri = Uri.parse(
      '$baseUrl/api/grammar/search',
    ).replace(queryParameters: queryParameters);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return {
        'total': data['total'] ?? 0,
        'results': data['results'] ?? [],
        'query': data['query'] ?? '',
        'level': data['level'],
        'limit': data['limit'] ?? limit,
        'offset': data['offset'] ?? offset,
      };
    } else {
      throw Exception(
        'Không thể tìm kiếm ngữ pháp: ${response.body}',
      );
    }
  }

  /// Lấy chi tiết một mẫu ngữ pháp
  Future<Map<String, dynamic>> getDetail(dynamic id) async {
    final uri = Uri.parse('$baseUrl/api/grammar/$id');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return Map<String, dynamic>.from(data['grammar']);
    } else if (response.statusCode == 404) {
      throw Exception('Không tìm thấy mẫu ngữ pháp.');
    } else {
      throw Exception(
        'Không thể lấy chi tiết ngữ pháp: ${response.body}',
      );
    }
  }
}
