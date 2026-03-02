import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_result.dart';
import '../../../core/utils/string_utils.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_form_widget.dart';
import '../widgets/google_sign_in_button.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    final result = await ref.read(authServiceProvider).signInWithGoogle();

    if (!mounted) return;

    setState(() => _isGoogleLoading = false);

    if (result case AppFailure(:final code)) {
      setState(() => _errorMessage = toUserMessage(code));
    }
    // On success, AuthWrapper reacts to the auth state change automatically.
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ref.read(authServiceProvider).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    setState(() => _isLoading = false);

    switch (result) {
      case AppSuccess():
        // AuthWrapper in main.dart reacts to the auth state change automatically.
        break;
      case AppFailure(:final code):
        setState(() => _errorMessage = toUserMessage(code));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'AllTogether',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 40),
                  AuthFormField(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 16),
                  AuthFormField(
                    label: 'Password',
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onEditingComplete: _signIn,
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 8),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const LoadingIndicator()
                      : FilledButton(
                          onPressed: _isGoogleLoading ? null : _signIn,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Text('Sign In'),
                          ),
                        ),
                  const SizedBox(height: 16),
                  const _OrDivider(),
                  const SizedBox(height: 16),
                  GoogleSignInButton(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    isLoading: _isGoogleLoading,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SignupScreen()),
                    ),
                    child: const Text("Don't have an account? Sign up"),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
