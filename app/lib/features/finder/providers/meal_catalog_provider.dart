import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/app_result.dart';
import '../models/meal_model.dart';
import '../models/preset_meals.dart';
import '../services/meal_catalog_service.dart';

/// Singleton [MealCatalogService].
final mealCatalogServiceProvider = Provider<MealCatalogService>(
  (_) => MealCatalogService(supabase: Supabase.instance.client),
);

/// Fetches the current user's custom meals from Supabase.
final userMealsProvider = FutureProvider<List<Meal>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];

  final result =
      await ref.read(mealCatalogServiceProvider).getUserMeals(userId);

  return switch (result) {
    AppSuccess(:final data) => data,
    AppFailure(:final message) => throw Exception(message),
  };
});

/// Merges [presetMeals] with the user's custom meals into a single list.
///
/// Preset meals come first, custom meals follow.
final allMealsProvider = Provider<AsyncValue<List<Meal>>>((ref) {
  final userMealsAsync = ref.watch(userMealsProvider);
  return userMealsAsync.whenData(
    (userMeals) => [...presetMeals, ...userMeals],
  );
});
