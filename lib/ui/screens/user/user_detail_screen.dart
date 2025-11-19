// lib/ui/screens/user/user_detail_screen.dart
import 'package:flutter/material.dart';

import '../../../services/user_service.dart';
import '../../../models/user.dart'; // where UserProfile is defined

class UserDetailScreen extends StatefulWidget {
  final String username;

  const UserDetailScreen({super.key, required this.username});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final UserService _userService = UserService();

  UserProfile? _profile;
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;

  bool _isFollowing = false;
  bool _isMe = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile =
          await _userService.getUserProfile(widget.username); // GET /users/:username

      final u = profile.user;

      setState(() {
        _profile = profile;
        _isFollowing = u.isFollowing;
        _isMe = u.isMe;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_profile == null || _isMe || _actionLoading) return;

    final currentlyFollowing = _isFollowing;

    // If we are going to unfollow, ask for confirmation
    if (currentlyFollowing) {
      final sure = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unfollow user'),
          content: Text(
            'Are you sure you want to stop following @${widget.username}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Unfollow',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );

      if (sure != true) return;
    }

    setState(() {
      _actionLoading = true;
    });

    try {
      if (!currentlyFollowing) {
        await _userService.followUser(widget.username);
        setState(() {
          _isFollowing = true;
        });
      } else {
        await _userService.unfollowUser(widget.username);
        setState(() {
          _isFollowing = false;
        });
      }
    } catch (e) {
      if (!mounted) return; // avoid use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _actionLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('@${widget.username}'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null || _profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('@${widget.username}'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  'Error loading profile',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? 'Unknown error',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadProfile,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final u = _profile!.user;

    return Scaffold(
      appBar: AppBar(
        title: Text('@${u.username}'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF020617),
              Color(0xFF050815),
              Color(0xFF0B1020),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: avatar + name + username
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFF1F2937),
                      child: Text(
                        u.username.isNotEmpty
                            ? u.username[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u.displayName ?? u.username,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${u.username}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Bio
                if ((u.bio ?? '').isNotEmpty) ...[
                  Text(
                    u.bio!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Follow / Unfollow button
                if (!_isMe)
                  SizedBox(
                    width: double.infinity,
                    child: _actionLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isFollowing
                                  ? Colors.redAccent
                                  : Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            onPressed: _toggleFollow,
                            child: Text(
                              _isFollowing ? 'Unfollow' : 'Follow',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),

                const SizedBox(height: 24),

                // Placeholder for more info: you can add stats, posts, etc. later
                Text(
                  'More info coming soon...\n(you can add stats, posts, etc. here).',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
