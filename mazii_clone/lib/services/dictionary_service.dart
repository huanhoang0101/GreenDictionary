import 'dart:convert';
import 'package:http/http.dart' as http;

class DictionaryService {
  // Android Emulator dùng địa chỉ này để truy cập máy tính.
  // Nếu chạy Flutter Web trên cùng máy tính, hãy đổi thành localhost.
  static const String baseUrl = 'http://localhost:3000';

  Future<List<dynamic>> search(String query) async {
    final uri = Uri.parse(
      '$baseUrl/api/dictionary/search',
    ).replace(
      queryParameters: {'q': query},
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['results'] as List<dynamic>;
    } else {
      throw Exception('Không thể tìm kiếm từ vựng');
    }
  }
}