import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_result.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/user_preferences_model.dart';
import '../services/preferences_service.dart';

/// Singleton [PreferencesService] accessible throughout the app.
final preferencesServiceProvider =
    Provider<PreferencesService>((_) => PreferencesService());

/// Loads the current user's preferences from Supabase.
///
/// Returns null when the user has not yet completed onboarding.
/// Throws when authentication is missing or a network error occurs.
final userPreferencesProvider =
    FutureProvider<UserPreferences?>((ref) async {
  final user = ref.read(authServiceProvider).currentUser;
  if (user == null) return null;

  final result =
      await ref.read(preferencesServiceProvider).getPreferences(user.id);

  return switch (result) {
    AppSuccess(:final data) => data,
    AppFailure(:final message) => throw Exception(message),
  };
});
