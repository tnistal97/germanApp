// lib/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../models/user.dart';

class AuthService {
  final ApiClient _client = ApiClient.instance;

  Future<(User, String)> register({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) async {
    final data = await _client.post(
      '/auth/register',
      body: {
        'username': username,
        'email': email,
        'password': password,
        'displayName': displayName,
      },
    );

    final user = User.fromJson(data['user']);
    final token = data['token'] as String;
    await _saveToken(token);
    return (user, token);
  }

  Future<(User, String)> login({
    required String email,
    required String password,
  }) async {
    final data = await _client.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    final user = User.fromJson(data['user']);
    final token = data['token'] as String;
    await _saveToken(token);
    return (user, token);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }
}
