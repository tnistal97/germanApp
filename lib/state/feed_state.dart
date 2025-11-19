import 'package:flutter/foundation.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../core/exceptions.dart';

class FeedState extends ChangeNotifier {
  final PostService _postService;

  bool _loading = false;
  String? _error;
  List<Post> _posts = [];

  // Local set of posts liked by the current user (for UI)
  final Set<int> _likedPostIds = {};

  bool get loading => _loading;
  String? get error => _error;
  List<Post> get posts => _posts;

  FeedState(this._postService);

  bool isLiked(Post post) => _likedPostIds.contains(post.id);

  Future<void> loadFeed() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _posts = await _postService.fetchFeed();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Unexpected error loading feed';
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> addPost(String content) async {
    try {
      final post = await _postService.createPost(content);
      _posts = [post, ..._posts];
      notifyListeners();
    } catch (_) {
      // handle error if you want
    }
  }

  Future<void> toggleLike(Post post) async {
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index == -1) return;

    final current = _posts[index];
    final liked = _likedPostIds.contains(post.id);

    // Optimistic UI update
    final newLikes =
        liked ? (current.likes - 1).clamp(0, 1 << 31) : current.likes + 1;
    if (liked) {
      _likedPostIds.remove(post.id);
    } else {
      _likedPostIds.add(post.id);
    }

    _posts[index] = Post(
      id: current.id,
      userId: current.userId,
      username: current.username,
      displayName: current.displayName,
      content: current.content,
      createdAt: current.createdAt,
      likes: newLikes,
      isOwner: current.isOwner,
    );
    notifyListeners();

    try {
      await _postService.likePost(post.id);
    } catch (_) {
      // You could rollback if you want
    }
  }

  // 👇 NEW: delete post
  Future<void> deletePost(Post post) async {
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index == -1) return;

    final removed = _posts[index];

    // Small "fun" UX: remove optimistically (instant UI)
    _posts = List.of(_posts)..removeAt(index);
    notifyListeners();

    try {
      await _postService.deletePost(post.id);
    } on ApiException catch (e) {
      // If backend failed, you could restore it
      if (kDebugMode) {
        print('❌ Delete failed: ${e.message}, restoring post');
      }
      _posts = List.of(_posts)..insert(index, removed);
      notifyListeners();
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected delete error: $e');
      }
      _posts = List.of(_posts)..insert(index, removed);
      notifyListeners();
      rethrow;
    }
  }
}
