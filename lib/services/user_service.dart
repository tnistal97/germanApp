// lib/services/user_service.dart
import '../core/api_client.dart';
import '../models/user.dart';

/// DTO for search results from GET /api/users?q=...
class UserSearchResult {
  final String id;
  final String username;
  final String? displayName;
  final String? bio;
  final DateTime? createdAt;

  UserSearchResult({
    required this.id,
    required this.username,
    this.displayName,
    this.bio,
    this.createdAt,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      displayName: (json['display_name'] ?? json['displayName'])?.toString(),
      bio: json['bio']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final ApiClient _apiClient = ApiClient.instance;

  /// GET /api/me  (via ApiClient base URL, so just '/me' here)
  Future<UserProfile> getCurrentUser() async {
    try {
      print('Fetching current user profile from /me ...');
      final response = await _apiClient.get('/users/me', auth: true);
      print('User profile response: $response');
      return UserProfile.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching current user: $e');
      rethrow;
    }
  }

  /// GET /api/users/:username
  Future<UserProfile> getUserProfile(String username) async {
    try {
      print('Fetching user profile for: $username');
      final response = await _apiClient.get('/users/username/$username', auth: true);
      print('User profile response: $response');

      return UserProfile.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching user profile: $e');
      rethrow;
    }
  }

  /// GET /api/users?q=term
  Future<List<UserSearchResult>> searchUsers(String query) async {
    try {
      final trimmed = query.trim();
      if (trimmed.isEmpty) return [];

      print('Searching users with q=$trimmed');
      final response = await _apiClient.get(
        '/users/users',
        auth: true,
        query: {'q': trimmed},
      );
      print('Search users response: $response');

      // searchUsersController returns a flat array of user rows
      if (response is List) {
        return response
            .whereType<Map<String, dynamic>>()
            .map(UserSearchResult.fromJson)
            .toList();
      }

      // if someday you change to { users: [...] }, we can support it:
      if (response is Map && response['users'] is List) {
        final list = response['users'] as List;
        return list
            .whereType<Map<String, dynamic>>()
            .map(UserSearchResult.fromJson)
            .toList();
      }

      return [];
    } catch (e) {
      print('Error searching users: $e');
      rethrow;
    }
  }

  /// POST /api/users/:username/follow
  Future<void> followUser(String username) async {
    try {
      await _apiClient.post(
        '/users/username/$username/follow',
        auth: true,
      );
    } catch (e) {
      print('Error following user: $e');
      rethrow;
    }
  }

  /// DELETE /api/users/:username/follow
  Future<void> unfollowUser(String username) async {
    try {
      await _apiClient.delete(
        '/users/username/$username/follow',
        auth: true,
      );
    } catch (e) {
      print('Error unfollowing user: $e');
      rethrow;
    }
  }
}
