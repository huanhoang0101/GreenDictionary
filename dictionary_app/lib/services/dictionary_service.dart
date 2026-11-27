
import 'dart:convert';
import 'package:http/http.dart' as http;

class DictionaryService {
  static const String baseUrl = 'http://localhost:3000';

  // Tìm kiếm từ vựng
  Future<List<dynamic>> search(String query) async {
    final uri = Uri.parse('$baseUrl/api/dictionary/search')
        .replace(queryParameters: {'q': query});

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['results'] as List<dynamic>;
    } else {
      throw Exception('Không thể tìm kiếm từ vựng');
    }
  }

  // Lấy từ vựng ngẫu nhiên
  Future<List<dynamic>> getRandomWords() async {
    final uri = Uri.parse('$baseUrl/api/dictionary/random');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['results'] as List<dynamic>;
    } else {
      throw Exception('Không thể lấy từ vựng ngẫu nhiên');
    }
  }

  // Lấy toàn bộ chi tiết một từ theo ID JMdict
  Future<Map<String, dynamic>> getWordDetail(String id) async {
    final uri = Uri.parse('$baseUrl/api/dictionary/$id');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return Map<String, dynamic>.from(data['word']);
    } else if (response.statusCode == 404) {
      throw Exception('Không tìm thấy từ vựng');
    } else {
      throw Exception('Không thể lấy chi tiết từ vựng');
    }
  }
}
