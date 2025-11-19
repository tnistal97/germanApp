// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'services/post_service.dart';
import 'state/auth_state.dart';
import 'state/feed_state.dart';
import 'theme/app_theme.dart';

// Screens
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/register_screen.dart';
import 'ui/screens/home/home_screen.dart';
import 'ui/screens/search/search_screen.dart';
import 'ui/screens/create/create_post_screen.dart';
import 'ui/screens/profile/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  final postService = PostService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthState(authService)..checkAuth(),
        ),
        ChangeNotifierProvider(
          create: (_) => FeedState(postService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'German Social',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const AuthGate(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/feed': (_) => const MainShell(), // 👈 feed = MainShell
      },
    );
  }
}

/// Widget que decide qué mostrar según el estado de autenticación
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    switch (auth.status) {
      case AuthStatus.unknown:
      case AuthStatus.loading:
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.authenticated:
        // Si ya está autenticado al abrir la app, lo mandamos directamente al feed
        return const MainShell();
    }
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const SearchScreen(),
      CreatePostScreen(
        onPosted: () {
          setState(() => _currentIndex = 0);
        },
      ),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF020617),
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: Colors.white60,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle),
              label: 'Create',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
