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
      // On web, redirect back to whatever URL the app is currently served from
      // (works for both localhost dev and GitHub Pages production).
      // On mobile, use the custom deep-link scheme registered in the OS.
      final redirectTo = kIsWeb
          ? Uri.base.toString()
          : 'io.supabase.alltogether://login-callback';

      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
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

  // ── Update User Name ───────────────────────────────────────────────────────

  Future<AppResult<void>> updateUserName(String newName) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return const AppFailure('Not authenticated');

      final lastChange = user.userMetadata?['last_name_change'] != null
          ? DateTime.parse(user.userMetadata!['last_name_change'] as String)
          : null;

      if (lastChange != null) {
        final now = DateTime.now();
        final difference = now.difference(lastChange);
        if (difference.inHours < 24) {
          return const AppFailure(
            'You can only change your username once every 24 hours.',
            code: 'limit_exceeded',
          );
        }
      }

      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'name': newName,
            'last_name_change': DateTime.now().toIso8601String(),
          },
        ),
      );

      return const AppSuccess(null);
    } on AuthException catch (e) {
      return AppFailure(e.message, code: 'auth_error');
    } catch (e) {
      return AppFailure('Unexpected error: $e');
    }
  }
}
