// lib/ui/screens/home/widgets/comments_bottom_sheet.dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/api_client.dart';
import '../../../../models/post.dart';

class CommentsBottomSheet extends StatefulWidget {
  final Post post;

  const CommentsBottomSheet({super.key, required this.post});

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _replyController = TextEditingController();
  final ApiClient _apiClient = ApiClient.instance;

  final List<Post> _replies = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReplies();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  /// Load replies from the API: GET /api/posts/:id/replies
  Future<void> _loadReplies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _apiClient.get(
        '/posts/${widget.post.id}/comments',
        auth: true,
      );

      final list = (data as List<dynamic>)
          .map((json) => Post.fromJson(json as Map<String, dynamic>))
          .toList();

      setState(() {
        _replies
          ..clear()
          ..addAll(list);
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Send a reply: POST /api/posts/:id/replies
  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      await _apiClient.post(
        '/posts/${widget.post.id}/comments',
        auth: true,
        body: {
          'content': text,
        },
      );

      _replyController.clear();
      await _loadReplies();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send reply: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  LinearGradient _getUserGradient(int index) {
    final gradients = [
      const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
      const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
      const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
      const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
    ];
    return gradients[index % gradients.length];
  }

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    final weeks = (diff.inDays / 7).floor();
    return '${weeks}w';
  }

  Widget _buildCommentItem(Post reply, int index) {
    final displayName = reply.displayName.isNotEmpty
        ? reply.displayName
        : reply.username;
    final timeAgo = _formatTimeAgo(reply.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: _getUserGradient(index),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                displayName.isNotEmpty
                    ? displayName[0].toUpperCase()
                    : reply.username.isNotEmpty
                        ? reply.username[0].toUpperCase()
                        : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + username + time
                Row(
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '@${reply.username}',
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (timeAgo.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF334155).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          timeAgo,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // Reply text (assuming your Post has 'content' or 'text')
                Text(
                  reply.content, // change to reply.text if your model uses 'text'
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                // Actions (no isLiked / likeCount to avoid undefined getters)
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        // hook up like reply here if you want later
                      },
                      icon: const Icon(
                        Icons.favorite_border_rounded,
                        size: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () {
                        // could open another reply-input targeted to this reply
                      },
                      icon: const Icon(
                        Icons.reply_rounded,
                        size: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepliesList(ScrollController scrollController) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent),
              const SizedBox(height: 8),
              const Text(
                'Failed to load replies',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _error!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loadReplies,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_replies.isEmpty) {
      return const Center(
        child: Text(
          'No replies yet.\nBe the first to comment!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _replies.length,
      itemBuilder: (_, index) => _buildCommentItem(_replies[index], index),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1E293B),
                Color(0xFF0F172A),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.comment_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Replies to ${widget.post.displayName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Join the conversation',
                                style: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Replies list
              Expanded(
                child: _buildRepliesList(scrollController),
              ),

              // Reply input
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF334155),
                          ),
                        ),
                        child: TextField(
                          controller: _replyController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Write a reply...',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          maxLines: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _isSending ? null : _sendReply,
                      child: Opacity(
                        opacity: _isSending ? 0.6 : 1,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
