import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/auth_state.dart';
import '../../../state/feed_state.dart';
import '../../../models/post.dart';
import '../auth/login_screen.dart';
import 'widgets/feed_header.dart';
import 'widgets/feed_loading_state.dart';
import 'widgets/feed_empty_state.dart';
import 'widgets/post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<FeedState>().loadFeed());

    _scrollController.addListener(() {
      if (_scrollController.offset > 400 && !_showScrollToTop) {
        setState(() => _showScrollToTop = true);
      } else if (_scrollController.offset <= 400 && _showScrollToTop) {
        setState(() => _showScrollToTop = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

Future<void> _deletePost(FeedState feed, Post post) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'Delete post',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );

  if (confirm == true) {
    await feed.deletePost(post);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Post deleted'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade800.withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final feed = context.watch<FeedState>();
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0A0F1F),
            Color(0xFF131B33),
            Color(0xFF1A2545),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.home_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Home',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Icon(Icons.refresh_rounded, size: 20),
              ),
              onPressed: feed.loadFeed,
            ),
            IconButton(
              tooltip: 'Logout',
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Icon(Icons.logout_rounded, size: 20),
              ),
              onPressed: () async {
                await auth.logout();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const LoginScreen(),
                    transitionsBuilder: (_, anim, __, child) {
                      return FadeTransition(opacity: anim, child: child);
                    },
                  ),
                  (_) => false,
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              FeedHeader(
                postCount: feed.posts.length,
                totalLikes: _calculateTotalLikes(feed.posts),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: feed.loading
                      ? const FeedLoadingState()
                      : feed.posts.isEmpty
                          ? const FeedEmptyState()
                          : _buildFeedList(feed, theme),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _showScrollToTop
            ? FloatingActionButton(
                onPressed: _scrollToTop,
                backgroundColor: const Color(0xFF6366F1),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildFeedList(FeedState feed, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: feed.loadFeed,
      backgroundColor: const Color(0xFF1E293B),
      color: const Color(0xFF6366F1),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: feed.posts.length,
        itemBuilder: (context, index) {
          final post = feed.posts[index];
          final liked = feed.isLiked(post);
          final isMine = (post as dynamic).isOwner == true;

          return PostCard(
            key: ValueKey(post.id),
            post: post,
            liked: liked,
            isMine: isMine,
            onLike: () => feed.toggleLike(post),
            onDelete: () => _deletePost(feed, post),
          );
        },
      ),
    );
  }

  static int _calculateTotalLikes(List<Post> posts) {
    return posts.fold(0, (sum, post) => sum + post.likes);
  }
}
