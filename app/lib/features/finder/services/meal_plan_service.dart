import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/models/app_result.dart';
import '../../../core/utils/cache_utils.dart';
import '../../../core/utils/crypto_utils.dart';
import '../../../features/customizations/models/user_preferences_model.dart';
import '../../../services/gemini_service.dart';
import '../models/meal_plan_model.dart';

/// Orchestrates meal plan generation: cache → Gemini API → Supabase → cache.
///
/// Call [getMealPlan] from the provider layer. Never call [GeminiService]
/// directly from a provider or screen.
class MealPlanService {
  final GeminiService _geminiService;
  final SupabaseClient _supabase;

  MealPlanService({
    required GeminiService claudeService,
    required SupabaseClient supabase,
  })  : _geminiService = claudeService,
        _supabase = supabase;

  static const _planTtl = Duration(days: 7);

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns the meal plan for [prefs], using cache when available.
  ///
  /// Set [forceRegenerate] to bypass the cache and always call Claude.
  Future<AppResult<MealPlan>> getMealPlan(
    UserPreferences prefs, {
    bool forceRegenerate = false,
  }) async {
    final fingerprint = sha256ofString(prefs.toFingerprintString());
    final box = Hive.box<String>(ApiConstants.mealPlanCacheBox);

    // 1. Cache check (skip when forcing regeneration)
    if (!forceRegenerate) {
      final cached =
          await getCached(box, fingerprint, MealPlan.fromJson);
      if (cached != null) {
        debugPrint('[MealPlanService] Cache hit for fingerprint $fingerprint');
        return AppSuccess(cached);
      }
    }

    // 2. Connectivity check before making a network call
    final connectivity = await Connectivity().checkConnectivity();
    final isOffline = connectivity.isEmpty ||
        connectivity.every((r) => r == ConnectivityResult.none);
    if (isOffline) {
      // Serve stale cache if available, otherwise surface offline error
      final stale = await getCached(box, fingerprint, MealPlan.fromJson);
      if (stale != null) return AppSuccess(stale);
      return const AppFailure(
        'No internet connection.',
        code: 'offline',
        isRetryable: true,
      );
    }

    // 3. Supabase check (missed Hive, try remote DB before calling Claude)
    if (!forceRegenerate) {
      try {
        final userId = _supabase.auth.currentUser?.id;
        if (userId != null) {
          final remoteData = await _supabase
              .from('meal_plans')
              .select()
              .eq('user_id', userId)
              .eq('pref_fingerprint', fingerprint)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

          if (remoteData != null) {
            final plan = MealPlan.fromSupabaseJson(remoteData);
            // Re-cache locally
            await setCache(box, fingerprint, plan, (p) => p.toJson(), _planTtl);
            debugPrint('[MealPlanService] Supabase hit for fingerprint $fingerprint');
            return AppSuccess(plan);
          }
        }
      } catch (e) {
        debugPrint('[MealPlanService] Remote fetch error: $e');
      }
    }

    // 4. Generate via Gemini API
    final geminiResult = await _geminiService.generateMealPlan(prefs);
    if (geminiResult is AppFailure<Map<String, dynamic>>) {
      return AppFailure(
        geminiResult.message,
        code: geminiResult.code,
        isRetryable: geminiResult.isRetryable,
      );
    }

    final planJson = (geminiResult as AppSuccess<Map<String, dynamic>>).data;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return const AppFailure('User session expired.', code: '401');
    }

    final plan = MealPlan.fromClaudeJson(planJson, userId, fingerprint);

    // 4. Persist to Supabase (upsert on pref_fingerprint + user_id)
    await _saveToSupabase(plan);

    // 5. Write to local cache
    await setCache(box, fingerprint, plan, (p) => p.toJson(), _planTtl);

    debugPrint('[MealPlanService] Generated and cached plan for $fingerprint');
    return AppSuccess(plan);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _saveToSupabase(MealPlan plan) async {
    try {
      await _supabase.from('meal_plans').upsert(
            plan.toSupabaseJson(),
            onConflict: 'user_id,pref_fingerprint',
          );
    } on PostgrestException catch (e) {
      // Non-fatal — local cache still serves the plan
      debugPrint('[MealPlanService] Supabase upsert failed: ${e.message}');
    } catch (e) {
      debugPrint('[MealPlanService] Supabase upsert error: $e');
    }
  }
}
