// lib/ui/screens/search/search_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';

import '../../../services/user_service.dart';
import '../user/user_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<UserSearchResult> _results = [];
  final UserService _userService = UserService();

  bool _isLoading = false;
  String? _error;
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results.clear();
        _error = null;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await _userService.searchUsers(trimmed);
      setState(() {
        _results
          ..clear()
          ..addAll(users);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _openUserDetail(UserSearchResult user) {
    // Later you can change this to a named route if you want.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(username: user.username),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Search'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                onChanged: _onQueryChanged,
                textInputAction: TextInputAction.search,
                onSubmitted: _search,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search users',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF111827),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading) const LinearProgressIndicator(minHeight: 2),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.redAccent,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Expanded(
                child: _results.isEmpty && !_isLoading && _error == null
                    ? Center(
                        child: Text(
                          'Search users by username or display name.\nResults will appear here.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium!
                              .copyWith(color: Colors.white70),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (context, __) =>
                            const Divider(color: Colors.white10, height: 1),
                        itemBuilder: (context, index) {
                          final user = _results[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF1F2937),
                              child: Text(
                                user.username.isNotEmpty
                                    ? user.username[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              user.username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: user.displayName != null ||
                                    user.bio != null
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (user.displayName != null)
                                        Text(
                                          user.displayName!,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      if (user.bio != null)
                                        Text(
                                          user.bio!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11,
                                          ),
                                        ),
                                    ],
                                  )
                                : null,
                            onTap: () => _openUserDetail(user),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
