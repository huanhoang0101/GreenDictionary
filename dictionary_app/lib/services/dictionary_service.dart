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

      // Hỗ trợ cả API trả về mảng trực tiếp
      // và API trả về { results: [...] }.
      if (data is List) return data;

      if (data is Map && data['results'] is List) {
        return data['results'] as List<dynamic>;
      }

      throw Exception('Định dạng kết quả tìm kiếm không hợp lệ');
    }

    throw Exception('Không thể tìm kiếm từ vựng: ${response.statusCode}');
  }

  // Lấy từ vựng ngẫu nhiên
  Future<List<dynamic>> getRandomWords() async {
    final uri = Uri.parse('$baseUrl/api/dictionary/random');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) return data;

      if (data is Map && data['results'] is List) {
        return data['results'] as List<dynamic>;
      }

      throw Exception('Định dạng dữ liệu từ ngẫu nhiên không hợp lệ');
    }

    throw Exception('Không thể lấy từ vựng ngẫu nhiên');
  }

  // Lấy chi tiết từ vựng.
  // Giữ toàn bộ response để WordDetailPage nhận được
  // word, partsOfSpeech và conjugation.
  Future<Map<String, dynamic>> getWordDetail(String id) async {
    final uri = Uri.parse('$baseUrl/api/dictionary/$id');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is! Map) {
        throw Exception('Dữ liệu chi tiết từ vựng không hợp lệ');
      }

      return Map<String, dynamic>.from(data);
    }

    if (response.statusCode == 404) {
      throw Exception('Không tìm thấy từ vựng');
    }

    throw Exception(
      'Không thể lấy chi tiết từ vựng: ${response.statusCode}',
    );
  }

  // Lấy nghĩa tiếng Việt suy luận từ Tatoeba.
  Future<Map<String, dynamic>> getInferredMeanings(String query) async {
    final uri = Uri.parse('$baseUrl/api/meanings/inferred')
        .replace(queryParameters: {'q': query});

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      throw Exception('Định dạng nghĩa tiếng Việt không hợp lệ');
    }

    throw Exception(
      'Không thể lấy nghĩa tiếng Việt: ${response.statusCode}',
    );
  }
}