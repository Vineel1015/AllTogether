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

  /// Creates or updates the user's preferences (upsert on `user_id`).
  Future<AppResult<UserPreferences>> savePreferences(
    UserPreferences prefs,
  ) async {
    try {
      final data = await _supabase
          .from('user_preferences')
          .upsert(prefs.toJson(), onConflict: 'user_id')
          .select()
          .order('id', ascending: false) // Fallback order
          .limit(1)
          .single();

      return AppSuccess(UserPreferences.fromJson(data));
    } on PostgrestException catch (e) {
      return switch (e.code) {
        '23505' => AppFailure('Preferences already exist.', code: e.code),
        '42501' => AppFailure('Permission denied.', code: e.code),
        _ => AppFailure(e.message, code: e.code, isRetryable: true),
      };
    } catch (e) {
      return AppFailure('Unexpected error: $e');
    }
  }
}
