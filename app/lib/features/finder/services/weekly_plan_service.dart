import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/models/app_result.dart';
import '../models/weekly_plan_model.dart';

/// Manages the user's current weekly meal plan in Supabase + local Hive cache.
class WeeklyPlanService {
  final SupabaseClient _supabase;

  WeeklyPlanService({required SupabaseClient supabase})
      : _supabase = supabase;

  static const _cacheTtl = Duration(hours: 24);

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns the active weekly plan for [userId], or null if none exists yet.
  Future<AppResult<WeeklyPlan?>> getPlan(String userId) async {
    final box = Hive.box<String>(ApiConstants.weeklyPlanCacheBox);

    // 1. Cache check
    final cached = _readCache(box, userId);
    if (cached != null) {
      debugPrint('[WeeklyPlanService] Cache hit for user $userId');
      return AppSuccess(cached);
    }

    // 2. Supabase fetch
    try {
      final row = await _supabase
          .from('weekly_plans')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (row == null) return const AppSuccess(null);

      final plan = WeeklyPlan.fromSupabaseJson(row);
      _writeCache(box, userId, plan);
      return AppSuccess(plan);
    } on PostgrestException catch (e) {
      debugPrint('[WeeklyPlanService] Supabase error: ${e.message}');
      return AppFailure('Failed to load plan: ${e.message}', code: e.code);
    } catch (e) {
      debugPrint('[WeeklyPlanService] Unexpected error: $e');
      return const AppFailure('Failed to load plan.', code: 'unknown');
    }
  }

  /// Upserts [plan] to Supabase (on conflict: user_id) and refreshes the cache.
  Future<AppResult<WeeklyPlan>> savePlan(WeeklyPlan plan) async {
    try {
      final row = await _supabase
          .from('weekly_plans')
          .upsert(
            plan.toSupabaseJson(),
            onConflict: 'user_id',
          )
          .select()
          .single();

      final saved = WeeklyPlan.fromSupabaseJson(row);

      // Refresh cache
      final box = Hive.box<String>(ApiConstants.weeklyPlanCacheBox);
      _writeCache(box, plan.userId, saved);

      return AppSuccess(saved);
    } on PostgrestException catch (e) {
      debugPrint('[WeeklyPlanService] Upsert error: ${e.message}');
      return AppFailure('Failed to save plan: ${e.message}', code: e.code);
    } catch (e) {
      debugPrint('[WeeklyPlanService] Unexpected error: $e');
      return const AppFailure('Failed to save plan.', code: 'unknown');
    }
  }

  // ── Cache helpers ─────────────────────────────────────────────────────────

  static WeeklyPlan? _readCache(Box<String> box, String userId) {
    final raw = box.get(userId);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(map['cachedAt'] as String);
      final ttl = Duration(seconds: map['ttlSeconds'] as int);
      if (DateTime.now().isAfter(cachedAt.add(ttl))) {
        box.delete(userId);
        return null;
      }
      return WeeklyPlan.fromJson(map['data'] as Map<String, dynamic>);
    } catch (_) {
      box.delete(userId);
      return null;
    }
  }

  static void _writeCache(Box<String> box, String userId, WeeklyPlan plan) {
    final map = {
      'data': plan.toJson(),
      'cachedAt': DateTime.now().toIso8601String(),
      'ttlSeconds': _cacheTtl.inSeconds,
    };
    box.put(userId, jsonEncode(map));
  }
}
