import '../core/api_client.dart';
import '../models/post.dart';
import '../models/comment.dart';

class PostService {
  final _client = ApiClient.instance;

  Future<List<Post>> fetchFeed() async {
    final data = await _client.get('/posts');
    final list = data as List<dynamic>;
    return list.map((json) => Post.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<(Post, List<Comment>)> fetchPostDetail(int id) async {
    final data = await _client.get('/posts/$id');
    final postJson = data['post'] as Map<String, dynamic>;
    final commentsJson = data['comments'] as List<dynamic>;

    final post = Post.fromJson(postJson);
    final comments = commentsJson
        .map((c) => Comment.fromJson(c as Map<String, dynamic>))
        .toList();

    return (post, comments);
  }

  Future<Post> createPost(String content) async {
    final data = await _client.post('/posts', auth: true, body: {
      'content': content,
    });
    return Post.fromJson(data as Map<String, dynamic>);
  }

  Future<int> likePost(int id) async {
    final data = await _client.post('/posts/$id/like', auth: true);
    return data['likes'] as int;
  }

  Future<int> unlikePost(int id) async {
    final data = await _client.delete('/posts/$id/like', auth: true);
    return data['likes'] as int;
  }

  Future<Comment> addComment(int postId, String content) async {
    final data = await _client.post('/posts/$postId/comments', auth: true, body: {
      'content': content,
    });
    return Comment.fromJson(data as Map<String, dynamic>);
  }
  
  Future<void> deletePost(int id) async {
    await _client.delete('/posts/$id', auth: true);
  }
}
