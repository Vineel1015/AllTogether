import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_result.dart';
import '../../../core/utils/string_utils.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_form_widget.dart';
import '../widgets/google_sign_in_button.dart';

enum _AuthMode { signIn, signUp }

/// Unified sign-in / sign-up screen.
///
/// Shown whenever the user is unauthenticated. Pass [startOnSignUp] = true
/// to open with the Sign Up tab pre-selected (used by [SignupScreen]).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.startOnSignUp = false});

  final bool startOnSignUp;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late _AuthMode _mode;

  // Sign-in form
  final _signInKey = GlobalKey<FormState>();
  final _siEmail = TextEditingController();
  final _siPassword = TextEditingController();

  // Sign-up form
  final _signUpKey = GlobalKey<FormState>();
  final _suName = TextEditingController();
  final _suEmail = TextEditingController();
  final _suPassword = TextEditingController();
  final _suConfirm = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _mode = widget.startOnSignUp ? _AuthMode.signUp : _AuthMode.signIn;
  }

  @override
  void dispose() {
    _siEmail.dispose();
    _siPassword.dispose();
    _suName.dispose();
    _suEmail.dispose();
    _suPassword.dispose();
    _suConfirm.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

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
  }

  Future<void> _signIn() async {
    if (!_signInKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final result = await ref.read(authServiceProvider).signIn(
          email: _siEmail.text.trim(),
          password: _siPassword.text,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result case AppFailure(:final code)) {
      setState(() => _errorMessage = toUserMessage(code));
    }
  }

  Future<void> _signUp() async {
    if (!_signUpKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final result = await ref.read(authServiceProvider).signUp(
          email: _suEmail.text.trim(),
          password: _suPassword.text,
          name: _suName.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result case AppFailure(:final code)) {
      setState(() => _errorMessage = toUserMessage(code));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.primary,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Heading ──────────────────────────────────────────
                    Text(
                      'Sign in or Sign up',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // ── Info banner ──────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.eco_outlined,
                              color: colors.onPrimaryContainer, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Track meals, scan receipts, and get AI meal plans.',
                              style: TextStyle(
                                color: colors.onPrimaryContainer,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Tab toggle ───────────────────────────────────────
                    SegmentedButton<_AuthMode>(
                      segments: const [
                        ButtonSegment(
                            value: _AuthMode.signIn, label: Text('Sign In')),
                        ButtonSegment(
                            value: _AuthMode.signUp, label: Text('Sign Up')),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (val) => setState(() {
                        _mode = val.first;
                        _errorMessage = null;
                      }),
                    ),
                    const SizedBox(height: 24),

                    // ── Google button ────────────────────────────────────
                    GoogleSignInButton(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      isLoading: _isGoogleLoading,
                    ),
                    const SizedBox(height: 16),

                    // ── Divider ──────────────────────────────────────────
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or continue with email',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Email form (switches based on tab) ───────────────
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _mode == _AuthMode.signIn
                          ? _SignInForm(
                              key: const ValueKey(_AuthMode.signIn),
                              formKey: _signInKey,
                              email: _siEmail,
                              password: _siPassword,
                              onSubmit: _signIn,
                            )
                          : _SignUpForm(
                              key: const ValueKey(_AuthMode.signUp),
                              formKey: _signUpKey,
                              name: _suName,
                              email: _suEmail,
                              password: _suPassword,
                              confirm: _suConfirm,
                              onSubmit: _signUp,
                            ),
                    ),

                    // ── Error message ────────────────────────────────────
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 16),

                    // ── CTA button ───────────────────────────────────────
                    _isLoading
                        ? const LoadingIndicator()
                        : FilledButton(
                            onPressed: _isGoogleLoading
                                ? null
                                : (_mode == _AuthMode.signIn
                                    ? _signIn
                                    : _signUp),
                            style: FilledButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              _mode == _AuthMode.signIn
                                  ? 'Continue to Sign In'
                                  : 'Continue to Sign Up',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                    const SizedBox(height: 16),

                    // ── Terms ────────────────────────────────────────────
                    Text(
                      'By continuing, you agree to our Terms of Service and Privacy Policy.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Private form widgets ───────────────────────────────────────────────────

class _SignInForm extends StatelessWidget {
  const _SignInForm({
    super.key,
    required this.formKey,
    required this.email,
    required this.password,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthFormField(
            label: 'Email',
            controller: email,
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 12),
          AuthFormField(
            label: 'Password',
            controller: password,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onEditingComplete: onSubmit,
            validator: (v) =>
                (v == null || v.length < 6) ? 'Min 6 characters' : null,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _SignUpForm extends StatelessWidget {
  const _SignUpForm({
    super.key,
    required this.formKey,
    required this.name,
    required this.email,
    required this.password,
    required this.confirm,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController confirm;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthFormField(
            label: 'Full Name',
            controller: name,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
          ),
          const SizedBox(height: 12),
          AuthFormField(
            label: 'Email',
            controller: email,
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 12),
          AuthFormField(
            label: 'Password',
            controller: password,
            obscureText: true,
            validator: (v) =>
                (v == null || v.length < 6) ? 'Min 6 characters' : null,
          ),
          const SizedBox(height: 12),
          AuthFormField(
            label: 'Confirm Password',
            controller: confirm,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onEditingComplete: onSubmit,
            validator: (v) =>
                v != password.text ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
