// lib/models/user.dart

class User {
  final int id;
  final String username;
  final String displayName;
  final String? email;
  final String? bio;
  final bool isMe;
  final bool isFollowing;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.username,
    required this.displayName,
    this.email,
    this.bio,
    required this.isMe,
    required this.isFollowing,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    String _string(dynamic v, {String fallback = ''}) {
      if (v is String) return v;
      return fallback;
    }

    String? _stringOrNull(dynamic v) {
      if (v is String) return v;
      return null;
    }

    final username = _string(json['username']);

    // Soporta displayName, display_name o cae al username
    final displayName = _string(
      json['displayName'] ?? json['display_name'],
      fallback: username,
    );

    // Soporta createdAt o created_at
    DateTime? createdAt;
    final createdRaw = json['createdAt'] ?? json['created_at'];
    if (createdRaw is String && createdRaw.isNotEmpty) {
      createdAt = DateTime.tryParse(createdRaw);
    }

    return User(
      id: (json['id'] as num).toInt(),
      username: username,
      displayName: displayName,
      email: _stringOrNull(json['email']),
      bio: _stringOrNull(json['bio']),
      isMe: json['isMe'] is bool ? json['isMe'] as bool : false,
      isFollowing:
          json['isFollowing'] is bool ? json['isFollowing'] as bool : false,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'email': email,
      'bio': bio,
      'isMe': isMe,
      'isFollowing': isFollowing,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class UserStats {
  final int postCount;
  final int followerCount;
  final int followingCount;

  UserStats({
    required this.postCount,
    required this.followerCount,
    required this.followingCount,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) {
        final parsed = int.tryParse(v);
        if (parsed != null) return parsed;
      }
      return 0;
    }

    // Backend envía { posts, followers, following }
    // pero soportamos también camelCase si algún día cambia
    return UserStats(
      postCount: _toInt(json['posts'] ?? json['postCount']),
      followerCount: _toInt(json['followers'] ?? json['followerCount']),
      followingCount: _toInt(json['following'] ?? json['followingCount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'posts': postCount,
      'followers': followerCount,
      'following': followingCount,
    };
  }
}

class UserProfile {
  final User user;
  final UserStats stats;

  UserProfile({
    required this.user,
    required this.stats,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      stats: UserStats.fromJson(json['stats'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'stats': stats.toJson(),
    };
  }
}

/// Resultados de búsqueda para SearchScreen
class UserSearchResult {
  final int id;
  final String username;
  final String? displayName;
  final String? bio;

  UserSearchResult({
    required this.id,
    required this.username,
    this.displayName,
    this.bio,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    String _string(dynamic v, {String fallback = ''}) {
      if (v is String) return v;
      return fallback;
    }

    final username = _string(json['username']);

    return UserSearchResult(
      id: (json['id'] as num).toInt(),
      username: username,
      // Soporta displayName o display_name si viene de una query directa SQL
      displayName: json['displayName'] as String? ??
          json['display_name'] as String?,
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'bio': bio,
    };
  }
}
