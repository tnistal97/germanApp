class Post {
  final int id;
  final int userId;
  final String username;
  final String displayName;
  final String content;
  final DateTime createdAt;
  final int likes;

  /// true if this post belongs to the logged-in user
  final bool isOwner;

  Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.content,
    required this.createdAt,
    required this.likes,
    required this.isOwner,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      username: json['username'] as String,
      displayName: json['display_name'] as String? ?? '',
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      likes: json['likes'] as int? ?? 0,
      // if backend doesn't send isOwner yet, this safely defaults to false
      isOwner: json['isOwner'] as bool? ?? false,
    );
  }
}
