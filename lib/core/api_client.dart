import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'app_env.dart';
import 'exceptions.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    // debug
    print('[ApiClient] Loaded token from SharedPreferences: $token');
    return token;
  }

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (auth) {
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        print('[ApiClient] No token found for auth request');
      }
    }

    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('${AppEnv.apiBaseUrl}$path')
        .replace(queryParameters: query);
    print('[ApiClient] Request URI: $uri');
    return uri;
  }

  Future<dynamic> get(String path,
      {bool auth = false, Map<String, dynamic>? query}) async {
    final uri = _uri(path, query);
    final headers = await _headers(auth: auth);

    print('[ApiClient] GET $uri');
    print('[ApiClient] Headers: $headers');

    final res = await http.get(uri, headers: headers);
    return _handleResponse(res);
  }

  Future<dynamic> post(String path,
      {bool auth = false, Map<String, dynamic>? body}) async {
    final uri = _uri(path);
    final headers = await _headers(auth: auth);

    print('[ApiClient] POST $uri');
    print('[ApiClient] Headers: $headers');
    print('[ApiClient] Body: $body');

    final res = await http.post(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(res);
  }

  Future<dynamic> delete(String path, {bool auth = false}) async {
    final uri = _uri(path);
    final headers = await _headers(auth: auth);

    print('[ApiClient] DELETE $uri');
    print('[ApiClient] Headers: $headers');

    final res = await http.delete(
      uri,
      headers: await _headers(auth: auth),
    );
    return _handleResponse(res);
  }

  dynamic _handleResponse(http.Response res) {
    final status = res.statusCode;
    dynamic data;

    try {
      data = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    } catch (_) {
      data = null;
    }

    print('[ApiClient] Response: status=$status, body=$data');

    if (status < 200 || status >= 300) {
      final msg = (data is Map && data['message'] is String)
          ? data['message'] as String
          : 'Request failed with status $status';

      throw ApiException(msg, statusCode: status);
    }

    return data;
  }
}
