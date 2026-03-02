import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

/// Singleton [AuthService] accessible throughout the app.
final authServiceProvider = Provider<AuthService>((_) => AuthService());

/// Streams Supabase [AuthState] changes (sign in, sign out, token refresh).
///
/// UI watches this to react to session changes without polling.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.read(authServiceProvider).authStateChanges;
});

/// Convenience provider — true when there is an active session.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return Supabase.instance.client.auth.currentSession != null;
});
