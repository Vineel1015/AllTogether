import 'dart:convert';

import 'meal_model.dart';

/// The user's current weekly meal plan.
class WeeklyPlan {
  final String? id;
  final String userId;
  final DateTime weekStartDate;
  final List<Meal> meals;
  final DateTime createdAt;

  const WeeklyPlan({
    this.id,
    required this.userId,
    required this.weekStartDate,
    required this.meals,
    required this.createdAt,
  });

  // ── Factories ─────────────────────────────────────────────────────────────

  factory WeeklyPlan.fromJson(Map<String, dynamic> json) =>
      WeeklyPlan.fromSupabaseJson(json);

  /// Deserializes a row from the Supabase `weekly_plans` table.
  factory WeeklyPlan.fromSupabaseJson(Map<String, dynamic> json) {
    final planData = json['plan_data'];
    final Map<String, dynamic> data = planData is String
        ? jsonDecode(planData) as Map<String, dynamic>
        : planData as Map<String, dynamic>;

    final mealsList = (data['meals'] as List? ?? [])
        .map((m) => Meal.fromJson(m as Map<String, dynamic>))
        .toList();

    return WeeklyPlan(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      weekStartDate: DateTime.parse(json['week_start_date'] as String),
      meals: mealsList,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  // ── Serializers ───────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => toSupabaseJson();

  /// Serializes for a Supabase upsert into `weekly_plans`.
  Map<String, dynamic> toSupabaseJson() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'week_start_date': _formatDate(weekStartDate),
        'plan_data': {
          'meals': meals.map((m) => m.toJson()).toList(),
        },
        'created_at': createdAt.toIso8601String(),
      };

  // ── Computed helpers ──────────────────────────────────────────────────────

  /// Sorted, unique ingredient list aggregated from all selected meals.
  List<String> get shoppingList {
    final all = <String>{};
    for (final meal in meals) {
      all.addAll(meal.ingredients.map((i) => i.trim().toLowerCase()));
    }
    final sorted = all.toList()..sort();
    return sorted;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  WeeklyPlan copyWith({
    String? id,
    String? userId,
    DateTime? weekStartDate,
    List<Meal>? meals,
    DateTime? createdAt,
  }) =>
      WeeklyPlan(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        weekStartDate: weekStartDate ?? this.weekStartDate,
        meals: meals ?? this.meals,
        createdAt: createdAt ?? this.createdAt,
      );

  static String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static DateTime startOfCurrentWeek() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }
}
