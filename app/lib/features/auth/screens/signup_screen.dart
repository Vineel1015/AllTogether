import 'package:flutter/material.dart';

import 'login_screen.dart';

/// Delegates to [LoginScreen] with the Sign Up tab pre-selected.
///
/// Kept as a named route so existing navigation calls continue to work.
class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen(startOnSignUp: true);
  }
}
