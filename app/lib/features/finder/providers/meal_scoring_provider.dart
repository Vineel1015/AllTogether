import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/meal_scoring_service.dart';
import 'weekly_plan_provider.dart';

/// Singleton [MealScoringService] — pure/stateless, safe to share.
final mealScoringServiceProvider = Provider<MealScoringService>(
  (_) => const MealScoringService(),
);

/// Composite 0–100 score for the user's current weekly plan.
///
/// Returns `null` when the plan is empty or not yet loaded.
final userPlanScoreProvider = Provider<double?>((ref) {
  final plan = ref.watch(weeklyPlanNotifierProvider).valueOrNull;
  return ref.read(mealScoringServiceProvider).scoreUserPlan(plan);
});
