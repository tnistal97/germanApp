// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/auth_state.dart';
import '../../../services/user_service.dart';
import '../../../models/user.dart'; // User, UserProfile, UserStats

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  UserProfile? _userProfile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    print('🔄 [Profile] Loading user profile...');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Always call /api/auth/me – token is handled by ApiClient
      final userProfile = await _userService.getCurrentUser();

      print('✅ [Profile] Parsed user profile: ${userProfile.user.displayName}');
      print('✅ [Profile] Stats: '
          '${userProfile.stats.postCount} posts, '
          '${userProfile.stats.followerCount} followers, '
          '${userProfile.stats.followingCount} following');

      if (!mounted) return;

      setState(() {
        _userProfile = userProfile;
      });

      // Optional: sync AuthState user with profile user
      context.read<AuthState>().updateUser(userProfile.user);
    } catch (e, st) {
      print('❌ [Profile] Error loading profile: $e');
      print(st);
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      // No 'return' in finally → avoids 'control_flow_in_finally' lint
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleFollow() async {
    if (_userProfile == null) return;

    try {
      final user = _userProfile!.user;
      if (user.isFollowing) {
        await _userService.unfollowUser(user.username);
      } else {
        await _userService.followUser(user.username);
      }

      await _loadUserProfile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update follow status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleLogout() {
    _showLogoutConfirmation(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ProfileLoadingView();
    }

    if (_error != null) {
      return ProfileErrorView(
        message: _error ?? 'Unknown error',
        onRetry: _loadUserProfile,
      );
    }

    final user = _userProfile!.user;
    final stats = _userProfile!.stats;

    return ProfileScaffold(
      appBarTitle: 'Profile',
      body: RefreshIndicator(
        onRefresh: _loadUserProfile,
        backgroundColor: const Color(0xFF1E293B),
        color: const Color(0xFF6366F1),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              ProfileHeaderCard(user: user),
              const SizedBox(height: 20),
              ProfileStatsCard(stats: stats),
              const SizedBox(height: 20),
              if (!user.isMe)
                ProfileConnectionCard(
                  user: user,
                  onFollow: _handleFollow,
                ),
              const SizedBox(height: 20),
              ProfileAccountInfoCard(
                user: user,
                formatJoinDate: _formatJoinDate,
              ),
              const SizedBox(height: 20),
              if (user.isMe)
                ProfileQuickActionsCard(
                  onLogout: _handleLogout,
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  String _formatJoinDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout? You will need to sign in again to access your account.',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthState>().logout();
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }
}

/// ----------------------
///  Smaller Components
/// ----------------------

class ProfileScaffold extends StatelessWidget {
  final String appBarTitle;
  final Widget body;

  const ProfileScaffold({
    super.key,
    required this.appBarTitle,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
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
          title: Text(
            appBarTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Icon(Icons.settings_rounded, size: 20),
              ),
              onPressed: () {},
            ),
          ],
        ),
        body: body,
      ),
    );
  }
}

class ProfileLoadingView extends StatelessWidget {
  const ProfileLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScaffold(
      appBarTitle: 'Profile',
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class ProfileErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const ProfileErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileScaffold(
      appBarTitle: 'Profile',
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print('🔁 [ProfileErrorView] Retry tapped');
                onRetry();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileHeaderCard extends StatelessWidget {
  final User user;

  const ProfileHeaderCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final initial = (user.displayName.isNotEmpty
            ? user.displayName.substring(0, 1)
            : user.username.substring(0, 1))
        .toUpperCase();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E293B),
            const Color(0xFF1E293B).withAlpha(230),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(76),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AvatarCircle(initial: initial),
                const SizedBox(width: 20),
                Expanded(
                  child: _UserBasicInfo(user: user),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (user.bio != null && user.bio!.isNotEmpty)
              _UserBio(bio: user.bio!),
          ],
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String initial;

  const _AvatarCircle({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withAlpha(102),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _UserBasicInfo extends StatelessWidget {
  final User user;

  const _UserBasicInfo({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.displayName,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '@${user.username}',
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        if (user.isMe)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withAlpha(38),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF10B981).withAlpha(76),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 12,
                  color: Color(0xFF10B981),
                ),
                SizedBox(width: 4),
                Text(
                  'Your Account',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _UserBio extends StatelessWidget {
  final String bio;

  const _UserBio({required this.bio});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: Color(0xFF64748B),
              ),
              SizedBox(width: 8),
              Text(
                'Bio',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            bio,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileStatsCard extends StatelessWidget {
  final UserStats stats;

  const ProfileStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E293B),
            const Color(0xFF1E293B).withAlpha(230),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.analytics_rounded,
                  size: 18,
                  color: Color(0xFF6366F1),
                ),
                SizedBox(width: 8),
                Text(
                  'Profile Overview',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Posts',
                  value: stats.postCount.toString(),
                  icon: Icons.edit_rounded,
                  color: const Color(0xFF6366F1),
                ),
                _StatItem(
                  label: 'Following',
                  value: stats.followingCount.toString(),
                  icon: Icons.people_alt_rounded,
                  color: const Color(0xFF10B981),
                ),
                _StatItem(
                  label: 'Followers',
                  value: stats.followerCount.toString(),
                  icon: Icons.favorite_rounded,
                  color: const Color(0xFFEF4444),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(76)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class ProfileConnectionCard extends StatelessWidget {
  final User user;
  final VoidCallback onFollow;

  const ProfileConnectionCard({
    super.key,
    required this.user,
    required this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E293B),
            const Color(0xFF1E293B).withAlpha(230),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(
                  Icons.person_add_rounded,
                  size: 18,
                  color: Color(0xFF6366F1),
                ),
                SizedBox(width: 8),
                Text(
                  'Connection',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: user.isFollowing
                      ? const Color(0xFF334155)
                      : const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  user.isFollowing ? 'Following' : 'Follow',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileAccountInfoCard extends StatelessWidget {
  final User user;
  final String Function(DateTime?) formatJoinDate;

  const ProfileAccountInfoCard({
    super.key,
    required this.user,
    required this.formatJoinDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E293B),
            const Color(0xFF1E293B).withAlpha(230),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(76),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 18,
                  color: Color(0xFF6366F1),
                ),
                SizedBox(width: 8),
                Text(
                  'Account Information',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'User ID',
              value: user.id.toString(),
              icon: Icons.fingerprint_rounded,
            ),
            if (user.email != null)
              _DetailRow(
                label: 'Email',
                value: user.email!,
                icon: Icons.email_rounded,
              ),
            _DetailRow(
              label: 'Member since',
              value: formatJoinDate(user.createdAt),
              icon: Icons.calendar_today_rounded,
            ),
            const _DetailRow(
              label: 'Account status',
              value: 'Active',
              icon: Icons.verified_user_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileQuickActionsCard extends StatelessWidget {
  final VoidCallback onLogout;

  const ProfileQuickActionsCard({
    super.key,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E293B),
            const Color(0xFF1E293B).withAlpha(230),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.settings_outlined,
                  size: 18,
                  color: Color(0xFF6366F1),
                ),
                SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ActionButton(
              label: 'Edit Profile',
              icon: Icons.edit_rounded,
              color: const Color(0xFF6366F1),
              onTap: () {},
            ),
            _ActionButton(
              label: 'Privacy Settings',
              icon: Icons.privacy_tip_rounded,
              color: const Color(0xFF10B981),
              onTap: () {},
            ),
            _ActionButton(
              label: 'Logout',
              icon: Icons.logout_rounded,
              color: const Color(0xFFEF4444),
              onTap: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
