import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/models/app_result.dart';
import '../models/meal_model.dart';

/// Manages user-created meals in Supabase + local Hive cache.
///
/// Preset meals are defined in [presetMeals] and never stored in Supabase.
class MealCatalogService {
  final SupabaseClient _supabase;

  MealCatalogService({required SupabaseClient supabase})
      : _supabase = supabase;

  static const _cacheTtl = Duration(hours: 1);
  static const _cacheKey = 'user_meals';

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns all meals created by [userId], using local cache when fresh.
  Future<AppResult<List<Meal>>> getUserMeals(String userId) async {
    final box = Hive.box<String>(ApiConstants.mealCatalogCacheBox);
    final key = '$_cacheKey:$userId';

    // 1. Cache check
    final cached = _readCache(box, key);
    if (cached != null) {
      debugPrint('[MealCatalogService] Cache hit for user $userId');
      return AppSuccess(cached);
    }

    // 2. Supabase fetch
    try {
      final rows = await _supabase
          .from('meals')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final meals = rows.map((r) => Meal.fromSupabaseJson(r)).toList();

      // 3. Write to cache
      _writeCache(box, key, meals);
      return AppSuccess(meals);
    } on PostgrestException catch (e) {
      debugPrint('[MealCatalogService] Supabase error: ${e.message}');
      return AppFailure('Failed to load meals: ${e.message}', code: e.code);
    } catch (e) {
      debugPrint('[MealCatalogService] Unexpected error: $e');
      return const AppFailure('Failed to load meals.', code: 'unknown');
    }
  }

  /// Creates a new user meal in Supabase and invalidates the local cache.
  Future<AppResult<Meal>> createMeal(Meal meal) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return const AppFailure('User session expired.', code: '401');
    }

    try {
      final row = await _supabase
          .from('meals')
          .insert(meal.toSupabaseJson())
          .select()
          .single();

      final created = Meal.fromSupabaseJson(row);

      // Invalidate cache
      final box = Hive.box<String>(ApiConstants.mealCatalogCacheBox);
      await box.delete('$_cacheKey:$userId');

      return AppSuccess(created);
    } on PostgrestException catch (e) {
      debugPrint('[MealCatalogService] Insert error: ${e.message}');
      return AppFailure('Failed to create meal: ${e.message}', code: e.code);
    } catch (e) {
      debugPrint('[MealCatalogService] Unexpected error: $e');
      return const AppFailure('Failed to create meal.', code: 'unknown');
    }
  }

  /// Deletes a user meal by [id] and invalidates the local cache.
  Future<AppResult<void>> deleteMeal(String id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return const AppFailure('User session expired.', code: '401');
    }

    try {
      await _supabase
          .from('meals')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);

      final box = Hive.box<String>(ApiConstants.mealCatalogCacheBox);
      await box.delete('$_cacheKey:$userId');

      return const AppSuccess(null);
    } on PostgrestException catch (e) {
      debugPrint('[MealCatalogService] Delete error: ${e.message}');
      return AppFailure('Failed to delete meal: ${e.message}', code: e.code);
    } catch (e) {
      debugPrint('[MealCatalogService] Unexpected error: $e');
      return const AppFailure('Failed to delete meal.', code: 'unknown');
    }
  }

  // ── Cache helpers ─────────────────────────────────────────────────────────

  static List<Meal>? _readCache(Box<String> box, String key) {
    final raw = box.get(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(map['cachedAt'] as String);
      final ttl = Duration(seconds: map['ttlSeconds'] as int);
      if (DateTime.now().isAfter(cachedAt.add(ttl))) {
        box.delete(key);
        return null;
      }
      return (map['meals'] as List)
          .map((m) => Meal.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      box.delete(key);
      return null;
    }
  }

  static void _writeCache(Box<String> box, String key, List<Meal> meals) {
    final map = {
      'meals': meals.map((m) => m.toJson()).toList(),
      'cachedAt': DateTime.now().toIso8601String(),
      'ttlSeconds': _cacheTtl.inSeconds,
    };
    box.put(key, jsonEncode(map));
  }
}
