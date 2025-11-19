import 'package:flutter/material.dart';

import '../../../../models/post.dart';
import 'comments_bottom_sheet.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final bool liked;
  final bool isMine;
  final VoidCallback onLike;
  final VoidCallback onDelete;

  const PostCard({
    super.key,
    required this.post,
    required this.liked,
    required this.isMine,
    required this.onLike,
    required this.onDelete,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _likeController;
  late final Animation<double> _scaleAnimation;
  late final Animation<Color?> _colorAnimation;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();

    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    // Start in the right position if the post is already liked
    if (widget.liked) {
      _likeController.value = 1.0;
    }

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.25,
    ).animate(
      CurvedAnimation(
        parent: _likeController,
        curve: Curves.elasticOut,
      ),
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey.shade400,
      end: const Color(0xFFEF4444),
    ).animate(_likeController);
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // When like state changes, animate
    if (!oldWidget.liked && widget.liked) {
      _likeController.forward(from: 0.2);
    } else if (oldWidget.liked && !widget.liked) {
      _likeController.reverse();
    }
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  Future<void> _openCommentsBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF020617),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => CommentsBottomSheet(post: widget.post),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  bool _hasLongContent(String content) {
    return content.length > 200 || content.split('\n').length > 4;
  }

  int _calculateReadTime(String content) {
    final words = content
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .length;
    return (words / 200).ceil().clamp(1, 10);
  }

  String _calculateEngagement(int likes) {
    if (likes >= 1000) {
      return '${(likes / 1000).toStringAsFixed(1)}k';
    }
    return likes.toString();
  }

  LinearGradient _getUserGradient(int userId) {
    final gradients = [
      const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
      const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
      const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
      const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
    ];
    return gradients[userId % gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    final liked = widget.liked;
    final isMine = widget.isMine;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: liked
              ? [
                  const Color(0xFF1E1032),
                  const Color(0xFF151627),
                ]
              : [
                  const Color(0xFF0F172A),
                  const Color(0xFF020617),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: liked
              ? const Color(0xFFEF4444).withOpacity(0.45)
              : const Color(0xFF1F2937),
          width: liked ? 1.6 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(liked ? 0.5 : 0.35),
            blurRadius: liked ? 26 : 18,
            offset: const Offset(0, 12),
          ),
          if (liked)
            BoxShadow(
              color: const Color(0xFFEF4444).withOpacity(0.18),
              blurRadius: 30,
              spreadRadius: 0.8,
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: _toggleExpand,
          splashColor: Colors.white.withOpacity(0.04),
          highlightColor: Colors.white.withOpacity(0.02),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _getUserGradient(widget.post.userId),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.post.displayName.isNotEmpty
                              ? widget.post.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Name + meta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.post.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15.5,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isMine
                                      ? const Color(0xFF22C55E)
                                          .withOpacity(0.18)
                                      : const Color(0xFF1F2937),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: isMine
                                        ? const Color(0xFF22C55E)
                                            .withOpacity(0.6)
                                        : const Color(0xFF4B5563),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isMine) ...[
                                      const Icon(
                                        Icons.person_rounded,
                                        size: 12,
                                        color: Color(0xFF22C55E),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      isMine ? 'You' : 'Member',
                                      style: TextStyle(
                                        color: isMine
                                            ? const Color(0xFF22C55E)
                                            : Colors.white.withOpacity(0.75),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '@${widget.post.username}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.55),
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.28),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatTime(widget.post.createdAt),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Read time + delete
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF020617),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.07),
                            ),
                          ),
                          child: Text(
                            '${_calculateReadTime(widget.post.content)} min',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(height: 4),
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: widget.onDelete,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: Colors.red.shade300.withOpacity(0.9),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // CONTENT
                AnimatedCrossFade(
                  firstChild: Text(
                    widget.post.content,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.white,
                    ),
                  ),
                  secondChild: Text(
                    widget.post.content,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.white,
                    ),
                  ),
                  crossFadeState: _isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 220),
                ),

                if (!_isExpanded && _hasLongContent(widget.post.content))
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Read more',
                      style: TextStyle(
                        color: Colors.blue.shade300,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                const SizedBox(height: 14),

                // FOOTER ACTIONS
                Row(
                  children: [
                    // LIKE
                    AnimatedBuilder(
                      animation: _likeController,
                      builder: (context, child) {
                        final color =
                            _colorAnimation.value ?? Colors.grey.shade400;
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: InkResponse(
                            onTap: widget.onLike,
                            radius: 24,
                            child: Icon(
                              liked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: color,
                              size: 22,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 2),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.post.likes}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.88),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if (liked)
                          Text(
                            'Liked by you',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // REPLY
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: _openCommentsBottomSheet,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.mode_comment_outlined,
                              size: 19,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Reply',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.82),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // ENGAGEMENT
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF020617),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 12,
                            color: Colors.white.withOpacity(0.65),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _calculateEngagement(widget.post.likes),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }
}
