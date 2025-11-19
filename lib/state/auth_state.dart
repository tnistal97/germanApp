import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../core/exceptions.dart';

enum AuthStatus { unknown, unauthenticated, authenticated, loading }

class AuthState extends ChangeNotifier {
  final AuthService _authService;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _error;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;

  AuthState(this._authService);

  // INITIAL TOKEN CHECK
  Future<void> checkAuth() async {
    print('🔍 [AuthState] Checking stored token...');
    _status = AuthStatus.loading;
    notifyListeners();

    final hasToken = await _authService.hasToken();

    if (hasToken) {
      print('🔍 [AuthState] Token found, user is authenticated');
      _status = AuthStatus.authenticated;
      // You SHOULD fetch /api/auth/me here later.
    } else {
      print('🔍 [AuthState] No token found, user is unauthenticated');
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  // LOGIN METHOD
  Future<void> login(String email, String password) async {
    print('🔐 [AuthState] Starting login for $email');
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final (user, token) =
          await _authService.login(email: email, password: password);

      print('✅ [AuthState] Login success — user: ${user.username}, token length: ${token.length}');

      _user = user;
      _status = AuthStatus.authenticated;
      _error = null;

    } on ApiException catch (e) {
      print('❌ [AuthState] API Exception: ${e.message}');
      _error = e.message;
      _status = AuthStatus.unauthenticated;
    } catch (e, st) {
      print('❌ [AuthState] Unexpected login error: $e');
      print(st);
      _error = 'Unexpected error';
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  // REGISTER
  Future<void> register(
    String username,
    String email,
    String password,
    String displayName,
  ) async {
    print('📝 [AuthState] Registering $email...');
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final (user, _) = await _authService.register(
        username: username,
        email: email,
        password: password,
        displayName: displayName,
      );

      print('📝 [AuthState] Registration OK — ${user.username}');

      _user = user;
      _status = AuthStatus.authenticated;

    } on ApiException catch (e) {
      print('❌ [AuthState] Registration API error: ${e.message}');
      _error = e.message;
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      print('❌ [AuthState] Registration unexpected error: $e');
      _error = 'Unexpected error';
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  // LOGOUT
  Future<void> logout() async {
    print('🚪 [AuthState] Logging out...');
    await _authService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // USED WHEN /api/auth/me RETURNS UPDATED USER
  void updateUser(User user) {
    print('🔄 [AuthState] Updating user: ${user.username}');
    _user = user;
    notifyListeners();
  }
}
