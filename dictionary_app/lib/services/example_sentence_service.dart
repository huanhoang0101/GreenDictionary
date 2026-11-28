import 'dart:convert';

import 'package:http/http.dart' as http;

class ExampleSentenceService {
  // Flutter Web / Chrome: localhost.
  // Android Emulator: change to http://10.0.2.2:3000.
  static const String baseUrl = 'http://localhost:3000';

  Future<List<Map<String, dynamic>>> searchExamples({
    required String query,
    String language = 'vi',
    int limit = 8,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return [];

    final uri = Uri.parse('$baseUrl/api/examples/search').replace(
      queryParameters: {
        'q': trimmedQuery,
        'language': language,
        'limit': limit.toString(),
      },
    );

    final response = await http.get(uri).timeout(
      const Duration(seconds: 15),
    );

    if (response.statusCode != 200) {
      throw Exception('Example API returned ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['results'] is! List) return [];

    return (decoded['results'] as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
