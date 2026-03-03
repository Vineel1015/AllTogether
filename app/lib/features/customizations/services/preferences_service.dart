import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/app_result.dart';
import '../models/user_preferences_model.dart';

/// Reads and writes user preferences from/to the `user_preferences` table.
///
/// All methods return [AppResult<T>]; no exceptions escape this class.
class PreferencesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Returns the user's saved preferences, or [AppSuccess(null)] if not set.
  Future<AppResult<UserPreferences?>> getPreferences(String userId) async {
    try {
      final data = await _supabase
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data == null) return const AppSuccess(null);
      return AppSuccess(UserPreferences.fromJson(data));
    } on PostgrestException catch (e) {
      return AppFailure(
        e.message,
        code: e.code,
        isRetryable: true,
      );
    } catch (e) {
      return AppFailure('Unexpected error: $e');
    }
  }

  /// Creates or updates the user's preferences.
  ///
  /// Checks for an existing row first so no UNIQUE constraint on `user_id`
  /// is required — works even if the schema only has a NOT NULL on `user_id`.
  Future<AppResult<UserPreferences>> savePreferences(
    UserPreferences prefs,
  ) async {
    try {
      // Check whether a row already exists for this user.
      final existing = await _supabase
          .from('user_preferences')
          .select('id')
          .eq('user_id', prefs.userId)
          .maybeSingle();

      final Map<String, dynamic> data;

      if (existing != null) {
        // UPDATE the existing row.
        data = await _supabase
            .from('user_preferences')
            .update(prefs.toJson())
            .eq('user_id', prefs.userId)
            .select()
            .single();
      } else {
        // INSERT a new row.
        data = await _supabase
            .from('user_preferences')
            .insert(prefs.toJson())
            .select()
            .single();
      }

      return AppSuccess(UserPreferences.fromJson(data));
    } on PostgrestException catch (e) {
      return switch (e.code) {
        '42501' => AppFailure('Permission denied.', code: e.code),
        _ => AppFailure(e.message, code: e.code, isRetryable: true),
      };
    } catch (e) {
      return AppFailure('Unexpected error: $e');
    }
  }
}
