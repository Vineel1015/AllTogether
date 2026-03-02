import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/app_result.dart';
import '../models/app_user_model.dart';

/// Wraps all Supabase authentication operations.
///
/// Every method returns [AppResult<T>] — callers never catch exceptions.
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ── Getters ───────────────────────────────────────────────────────────────

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  // ── Sign Up ───────────────────────────────────────────────────────────────

  Future<AppResult<AppUser>> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (response.user == null) {
        return const AppFailure(
          'Sign up failed. Please try again.',
          code: 'auth_error',
        );
      }

      return AppSuccess(AppUser.fromSupabaseUser(response.user!));
    } on AuthException catch (e) {
      return AppFailure(e.message, code: 'auth_error');
    } catch (e) {
      return AppFailure('Unexpected error: $e');
    }
  }

  // ── Sign In ───────────────────────────────────────────────────────────────

  Future<AppResult<AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return const AppFailure(
          'Sign in failed. Please check your credentials.',
          code: 'auth_error',
        );
      }

      return AppSuccess(AppUser.fromSupabaseUser(response.user!));
    } on AuthException catch (e) {
      return AppFailure(e.message, code: 'auth_error');
    } catch (e) {
      return AppFailure('Unexpected error: $e');
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────

  Future<AppResult<void>> signOut() async {
    try {
      await _supabase.auth.signOut();
      return const AppSuccess(null);
    } on AuthException catch (e) {
      return AppFailure(e.message, code: 'auth_error');
    } catch (e) {
      return AppFailure('Unexpected error: $e');
    }
  }

  // ── Google OAuth ──────────────────────────────────────────────────────────

  Future<AppResult<void>> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.alltogether://login-callback',
      );
      // Session arrives asynchronously via authStateProvider stream.
      return const AppSuccess(null);
    } on AuthException catch (e) {
      return AppFailure(e.message, code: 'auth_error');
    } catch (e) {
      return AppFailure('Unexpected error: $e');
    }
  }

  // ── Password Reset ────────────────────────────────────────────────────────

  Future<AppResult<void>> sendPasswordReset(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return const AppSuccess(null);
    } on AuthException catch (e) {
      return AppFailure(e.message, code: 'auth_error');
    } catch (e) {
      return AppFailure('Unexpected error: $e');
    }
  }
}
