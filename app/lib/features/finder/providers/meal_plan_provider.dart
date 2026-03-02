import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/app_result.dart';
import '../../../services/gemini_service.dart';
import '../../customizations/providers/preferences_provider.dart';
import '../models/meal_plan_model.dart';
import '../services/meal_plan_service.dart';

/// Singleton [GeminiService] — shares one HTTP client across the app.
final geminiServiceProvider = Provider<GeminiService>(
  (_) => GeminiService(),
);

/// Singleton [MealPlanService] wired to [GeminiService] and Supabase.
final mealPlanServiceProvider = Provider<MealPlanService>((ref) {
  return MealPlanService(
    claudeService: ref.read(geminiServiceProvider),
    supabase: Supabase.instance.client,
  );
});

/// Loads (or regenerates) the current user's meal plan.
///
/// Backed by [MealPlanNotifier] so screens can call [regenerate()] without
/// manually invalidating the provider.
final mealPlanNotifierProvider =
    AsyncNotifierProvider<MealPlanNotifier, MealPlan?>(
  MealPlanNotifier.new,
);

class MealPlanNotifier extends AsyncNotifier<MealPlan?> {
  @override
  Future<MealPlan?> build() async {
    final prefsAsync = await ref.watch(userPreferencesProvider.future);
    if (prefsAsync == null) return null;

    final result = await ref
        .read(mealPlanServiceProvider)
        .getMealPlan(prefsAsync);

    return switch (result) {
      AppSuccess(:final data) => data,
      AppFailure(:final message, :final code) => throw Exception('[$code] $message'),
    };
  }

  /// Forces a fresh Claude API call, ignoring the local cache.
  Future<void> regenerate() async {
    final prefs = await ref.read(userPreferencesProvider.future);
    if (prefs == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref
          .read(mealPlanServiceProvider)
          .getMealPlan(prefs, forceRegenerate: true);

      return switch (result) {
        AppSuccess(:final data) => data,
        AppFailure(:final message, :final code) => throw Exception('[$code] $message'),
      };
    });
  }
}
