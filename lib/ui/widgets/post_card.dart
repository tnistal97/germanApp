import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/post.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
  });

  String _formatTime(DateTime dt) {
    // Simple: HH:mm or date
    return DateFormat('HH:mm · dd MMM').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header
              Row(
                children: [
                  CircleAvatar(
                    child: Text(post.displayName.isNotEmpty
                        ? post.displayName[0].toUpperCase()
                        : post.username[0].toUpperCase()),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '@${post.username}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatTime(post.createdAt),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                post.content,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: onLike,
                    icon: const Icon(Icons.favorite_border),
                    visualDensity: VisualDensity.compact,
                  ),
                  Text('${post.likes}'),
                  const Spacer(),
                  const Icon(Icons.mode_comment_outlined, size: 18),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
