import 'dart:convert';
import 'package:http/http.dart' as http;

/// The operational API is the source of truth for both clients.
/// Tokens stay in memory; passwords are never saved by the Flutter client.
class OperationsApi {
  OperationsApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? const String.fromEnvironment(
          'API_URL', defaultValue: 'http://127.0.0.1:8080');
  final http.Client _client;
  final String baseUrl;
  String? token;

  Future<Map<String, dynamic>> request(String path,
      [Map<String, dynamic>? data]) async {
    final uri = Uri.parse('$baseUrl/api/$path');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response = await (data == null
        ? _client.get(uri, headers: headers)
        : _client.post(uri, headers: headers, body: jsonEncode(data)))
        .timeout(const Duration(seconds: 10));
    final result = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      if (response.statusCode == 401) token = null;
      throw Exception(result['error'] ?? 'Request failed');
    }
    return result;
  }

  Future<void> login(String email, String password) async {
    final result = await request('login', {'email': email, 'password': password});
    token = result['token'] as String;
  }

  void close() => _client.close();
}
