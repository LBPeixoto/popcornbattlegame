import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiClient {
  final http.Client _http;
  final StorageService _storage;

  ApiClient(this._storage, {http.Client? client}) : _http = client ?? http.Client();

  Map<String, String> get _headers {
    final token = _storage.token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String url) async {
    final response = await _http.get(Uri.parse(url), headers: _headers);
    return _handle(response);
  }

  Future<dynamic> post(String url, {Object? body}) async {
    final response = await _http.post(
      Uri.parse(url),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(response);
  }

  Future<dynamic> delete(String url) async {
    final response = await _http.delete(Uri.parse(url), headers: _headers);
    return _handle(response);
  }

  dynamic _handle(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    String message = 'Erro ${response.statusCode}';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = body['message'] as String? ?? message;
    } catch (_) {}
    throw ApiException(response.statusCode, message);
  }
}
