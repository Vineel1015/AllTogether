import 'package:flutter/foundation.dart';
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

    switch (result) {
      case AppSuccess(:final data):
        return data;
      case AppFailure(:final code, :final message):
        // Auth failure: re-throw so the finder screen can sign the user out.
        if (code == '401' || code == 'JWT expired') {
          throw Exception('[$code] $message');
        }
        // Table not found or any other backend issue: show empty plan rather
        // than blocking the whole Finder tab with an error screen.
        debugPrint('[WeeklyPlanNotifier] Non-fatal load error [$code]: $message');
        return null;
    }
  }

  /// Adds [meal] to the plan and persists to Supabase.
  ///
  /// Applies the change optimistically; reverts to the previous state if the
  /// save fails so the UI stays consistent.
  Future<void> addMeal(Meal meal) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final previous = state;
    final current = state.valueOrNull;

    // Optimistic update
    final updated = WeeklyPlan(
      id: current?.id,
      userId: userId,
      weekStartDate:
          current?.weekStartDate ?? WeeklyPlan.startOfCurrentWeek(),
      meals: [...(current?.meals ?? []), meal],
      createdAt: current?.createdAt ?? DateTime.now(),
    );
    state = AsyncData(updated);

    final result =
        await ref.read(weeklyPlanServiceProvider).savePlan(updated);

    switch (result) {
      case AppSuccess(:final data):
        state = AsyncData(data);
      case AppFailure(:final code, :final message):
        debugPrint('[WeeklyPlanNotifier] addMeal failed [$code]: $message');
        state = previous; // revert
    }
  }

  /// Removes the meal with [mealId] from the plan and persists to Supabase.
  Future<void> removeMeal(String mealId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final previous = state;
    final current = state.valueOrNull;
    if (current == null) return;

    // Optimistic update
    final updated = current.copyWith(
      meals: current.meals.where((m) => m.id != mealId).toList(),
    );
    state = AsyncData(updated);

    final result =
        await ref.read(weeklyPlanServiceProvider).savePlan(updated);

    switch (result) {
      case AppSuccess(:final data):
        state = AsyncData(data);
      case AppFailure(:final code, :final message):
        debugPrint('[WeeklyPlanNotifier] removeMeal failed [$code]: $message');
        state = previous; // revert
    }
  }

  /// Empties the plan and persists to Supabase.
  Future<void> clearPlan() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final previous = state;
    final current = state.valueOrNull;

    final cleared = WeeklyPlan(
      id: current?.id,
      userId: userId,
      weekStartDate:
          current?.weekStartDate ?? WeeklyPlan.startOfCurrentWeek(),
      meals: const [],
      createdAt: current?.createdAt ?? DateTime.now(),
    );
    state = AsyncData(cleared);

    final result =
        await ref.read(weeklyPlanServiceProvider).savePlan(cleared);

    switch (result) {
      case AppSuccess(:final data):
        state = AsyncData(data);
      case AppFailure(:final code, :final message):
        debugPrint('[WeeklyPlanNotifier] clearPlan failed [$code]: $message');
        state = previous; // revert
    }
  }
}
