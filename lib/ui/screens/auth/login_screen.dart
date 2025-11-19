// lib/ui/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/auth_state.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final loading = auth.status == AuthStatus.loading;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'German Social',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                AppTextField(label: 'Email', controller: emailCtrl),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Password',
                  controller: passCtrl,
                  obscure: true,
                ),
                const SizedBox(height: 16),
                if (auth.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      auth.error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                PrimaryButton(
                  label: 'Sign in',
                  loading: loading,
                  onPressed: () async {
                    await context.read<AuthState>().login(
                          emailCtrl.text.trim(),
                          passCtrl.text.trim(),
                        );

                    if (!mounted) return;

                    final authState = context.read<AuthState>();
                    if (authState.status == AuthStatus.authenticated) {
                      // 👇 Ahora sí, redirigimos al "feed" (MainShell)
                      Navigator.pushReplacementNamed(context, '/feed');
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text("Don't have an account? Sign up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
