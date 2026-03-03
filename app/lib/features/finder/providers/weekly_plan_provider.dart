import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/app_result.dart';
import '../models/meal_model.dart';
import '../models/weekly_plan_model.dart';
import '../services/weekly_plan_service.dart';

/// Singleton [WeeklyPlanService].
final weeklyPlanServiceProvider = Provider<WeeklyPlanService>(
  (_) => WeeklyPlanService(supabase: Supabase.instance.client),
);

/// Loads the current user's weekly plan and exposes mutation methods.
final weeklyPlanNotifierProvider =
    AsyncNotifierProvider<WeeklyPlanNotifier, WeeklyPlan?>(
  WeeklyPlanNotifier.new,
);

class WeeklyPlanNotifier extends AsyncNotifier<WeeklyPlan?> {
  @override
  Future<WeeklyPlan?> build() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;

    final result =
        await ref.read(weeklyPlanServiceProvider).getPlan(userId);

    return switch (result) {
      AppSuccess(:final data) => data,
      AppFailure(:final message, :final code) =>
        throw Exception('[$code] $message'),
    };
  }

  /// Adds [meal] to the plan and persists to Supabase.
  Future<void> addMeal(Meal meal) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final current = state.valueOrNull;
    final updatedMeals = [...(current?.meals ?? []), meal];

    final updated = WeeklyPlan(
      id: current?.id,
      userId: userId,
      weekStartDate:
          current?.weekStartDate ?? WeeklyPlan.startOfCurrentWeek(),
      meals: updatedMeals,
      createdAt: current?.createdAt ?? DateTime.now(),
    );

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result =
          await ref.read(weeklyPlanServiceProvider).savePlan(updated);
      return switch (result) {
        AppSuccess(:final data) => data,
        AppFailure(:final message, :final code) =>
          throw Exception('[$code] $message'),
      };
    });
  }

  /// Removes the meal with [mealId] from the plan and persists to Supabase.
  Future<void> removeMeal(String mealId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final current = state.valueOrNull;
    if (current == null) return;

    final updatedMeals =
        current.meals.where((m) => m.id != mealId).toList();

    final updated = current.copyWith(meals: updatedMeals);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result =
          await ref.read(weeklyPlanServiceProvider).savePlan(updated);
      return switch (result) {
        AppSuccess(:final data) => data,
        AppFailure(:final message, :final code) =>
          throw Exception('[$code] $message'),
      };
    });
  }

  /// Empties the plan and persists to Supabase.
  Future<void> clearPlan() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final current = state.valueOrNull;
    final cleared = WeeklyPlan(
      id: current?.id,
      userId: userId,
      weekStartDate:
          current?.weekStartDate ?? WeeklyPlan.startOfCurrentWeek(),
      meals: const [],
      createdAt: current?.createdAt ?? DateTime.now(),
    );

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result =
          await ref.read(weeklyPlanServiceProvider).savePlan(cleared);
      return switch (result) {
        AppSuccess(:final data) => data,
        AppFailure(:final message, :final code) =>
          throw Exception('[$code] $message'),
      };
    });
  }
}
