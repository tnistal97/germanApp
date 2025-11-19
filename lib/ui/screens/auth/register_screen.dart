import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/auth_state.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final usernameCtrl = TextEditingController();
  final displayNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  void dispose() {
    usernameCtrl.dispose();
    displayNameCtrl.dispose();
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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    'Create your account',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  AppTextField(label: 'Username', controller: usernameCtrl),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Display name', controller: displayNameCtrl),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Email', controller: emailCtrl),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Password', controller: passCtrl, obscure: true),
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
                    label: 'Sign up',
                    loading: loading,
                    onPressed: () async {
                      await context.read<AuthState>().register(
                            usernameCtrl.text.trim(),
                            emailCtrl.text.trim(),
                            passCtrl.text.trim(),
                            displayNameCtrl.text.trim(),
                          );
                      if (context.read<AuthState>().status == AuthStatus.authenticated) {
                        if (!mounted) return;
                        Navigator.pushReplacementNamed(context, '/feed');
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text('Already have an account? Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
