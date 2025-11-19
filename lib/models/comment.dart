class Comment {
  final int id;
  final int postId;
  final int userId;
  final String username;
  final String displayName;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int,
      postId: json['post_id'] as int,
      userId: json['user_id'] as int,
      username: json['username'] as String,
      displayName: json['display_name'] as String? ?? '',
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
