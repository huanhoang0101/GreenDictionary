
import 'dart:convert';
import 'package:http/http.dart' as http;

class InferredMeaningService {
  static const String baseUrl = 'http://localhost:3000';

  Future<Map<String, dynamic>> getInferredMeanings({
    required String query,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return {};

    final uri = Uri.parse(
      '$baseUrl/api/meanings/inferred',
    ).replace(
      queryParameters: {'q': trimmedQuery},
    );

    final response = await http.get(uri).timeout(
      const Duration(seconds: 15),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Inferred Meaning API returned ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception('Invalid inferred meaning response');
    }

    return Map<String, dynamic>.from(decoded);
  }
}
