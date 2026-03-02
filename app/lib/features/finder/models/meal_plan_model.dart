import 'dart:convert';

/// A single meal (breakfast, lunch, dinner, or snack).
class MealEntry {
  final String name;
  final List<String> ingredients;
  final int calories;
  final int prepMinutes;

  const MealEntry({
    required this.name,
    required this.ingredients,
    required this.calories,
    required this.prepMinutes,
  });

  factory MealEntry.fromJson(Map<String, dynamic> json) => MealEntry(
        name: json['name'] as String? ?? '',
        ingredients: List<String>.from(json['ingredients'] as List? ?? []),
        calories: (json['calories'] as num?)?.toInt() ?? 0,
        prepMinutes: (json['prep_minutes'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'ingredients': ingredients,
        'calories': calories,
        'prep_minutes': prepMinutes,
      };
}

/// One day's worth of meals.
class DayPlan {
  final String day;
  final MealEntry breakfast;
  final MealEntry lunch;
  final MealEntry dinner;
  final MealEntry snack;

  const DayPlan({
    required this.day,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snack,
  });

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    final meals = json['meals'] as Map<String, dynamic>? ?? {};
    return DayPlan(
      day: json['day'] as String? ?? '',
      breakfast: MealEntry.fromJson(
          meals['breakfast'] as Map<String, dynamic>? ?? {}),
      lunch: MealEntry.fromJson(meals['lunch'] as Map<String, dynamic>? ?? {}),
      dinner:
          MealEntry.fromJson(meals['dinner'] as Map<String, dynamic>? ?? {}),
      snack: MealEntry.fromJson(meals['snack'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'meals': {
          'breakfast': breakfast.toJson(),
          'lunch': lunch.toJson(),
          'dinner': dinner.toJson(),
          'snack': snack.toJson(),
        },
      };
}

/// One item on the generated shopping list.
class ShoppingItem {
  final String item;
  final String quantity;
  final double estimatedCost;

  const ShoppingItem({
    required this.item,
    required this.quantity,
    required this.estimatedCost,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        item: json['item'] as String? ?? '',
        quantity: json['quantity'] as String? ?? '',
        estimatedCost: (json['estimated_cost'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'item': item,
        'quantity': quantity,
        'estimated_cost': estimatedCost,
      };
}

/// A 7-day meal plan as returned by Claude and persisted in Supabase.
class MealPlan {
  final String? id;
  final String userId;
  final DateTime createdAt;
  final DateTime weekStartDate;
  final List<DayPlan> days;
  final List<ShoppingItem> shoppingList;
  final String prefFingerprint;

  const MealPlan({
    this.id,
    required this.userId,
    required this.createdAt,
    required this.weekStartDate,
    required this.days,
    required this.shoppingList,
    required this.prefFingerprint,
  });

  // ── Factories ─────────────────────────────────────────────────────────────

  /// Parses the raw JSON map returned by Claude into a [MealPlan].
  factory MealPlan.fromClaudeJson(
    Map<String, dynamic> json,
    String userId,
    String prefFingerprint,
  ) {
    final weekStart = _parseWeekStart(json['week_start'] as String?);
    return MealPlan(
      userId: userId,
      createdAt: DateTime.now(),
      weekStartDate: weekStart,
      days: (json['days'] as List? ?? [])
          .map((d) => DayPlan.fromJson(d as Map<String, dynamic>))
          .toList(),
      shoppingList: (json['shopping_list'] as List? ?? [])
          .map((s) => ShoppingItem.fromJson(s as Map<String, dynamic>))
          .toList(),
      prefFingerprint: prefFingerprint,
    );
  }

  /// Deserializes a row returned from the Supabase `meal_plans` table.
  factory MealPlan.fromSupabaseJson(Map<String, dynamic> json) {
    final planData = json['plan_data'];
    final Map<String, dynamic> data = planData is String
        ? jsonDecode(planData) as Map<String, dynamic>
        : planData as Map<String, dynamic>;

    return MealPlan(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      weekStartDate: DateTime.parse(json['week_start_date'] as String),
      days: (data['days'] as List? ?? [])
          .map((d) => DayPlan.fromJson(d as Map<String, dynamic>))
          .toList(),
      shoppingList: (data['shopping_list'] as List? ?? [])
          .map((s) => ShoppingItem.fromJson(s as Map<String, dynamic>))
          .toList(),
      prefFingerprint: json['pref_fingerprint'] as String? ?? '',
    );
  }

  /// Deserializes from the Hive cache (same shape as Supabase row).
  factory MealPlan.fromJson(Map<String, dynamic> json) =>
      MealPlan.fromSupabaseJson(json);

  // ── Serializers ───────────────────────────────────────────────────────────

  /// Serializes for the Hive cache (mirrors [toSupabaseJson]).
  Map<String, dynamic> toJson() => toSupabaseJson();

  /// Serializes for a Supabase upsert into `meal_plans`.
  Map<String, dynamic> toSupabaseJson() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'created_at': createdAt.toIso8601String(),
        'week_start_date': _formatDate(weekStartDate),
        'plan_data': {
          'week_start': _formatDate(weekStartDate),
          'days': days.map((d) => d.toJson()).toList(),
          'shopping_list': shoppingList.map((s) => s.toJson()).toList(),
        },
        'pref_fingerprint': prefFingerprint,
      };

  // ── Computed helpers ──────────────────────────────────────────────────────

  double get totalEstimatedCost =>
      shoppingList.fold(0.0, (sum, item) => sum + item.estimatedCost);

  // ── Private helpers ───────────────────────────────────────────────────────

  static DateTime _parseWeekStart(String? raw) {
    if (raw == null) return _startOfCurrentWeek();
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return _startOfCurrentWeek();
    }
  }

  static DateTime _startOfCurrentWeek() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  static String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
