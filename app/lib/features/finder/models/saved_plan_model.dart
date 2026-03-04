import 'meal_model.dart';

class SavedPlan {
  final String id;
  final String userId;
  final DateTime weekStartDate;
  final List<Meal> meals;
  final List<String> shoppingList;
  final double? actualTotalCost;
  final DateTime createdAt;

  const SavedPlan({
    required this.id,
    required this.userId,
    required this.weekStartDate,
    required this.meals,
    required this.shoppingList,
    this.actualTotalCost,
    required this.createdAt,
  });

  factory SavedPlan.fromJson(Map<String, dynamic> json) {
    return SavedPlan(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      weekStartDate: DateTime.parse(json['week_start_date'] as String),
      meals: (json['meals'] as List).map((m) => Meal.fromJson(m)).toList(),
      shoppingList: List<String>.from(json['shopping_list'] ?? []),
      actualTotalCost: (json['actual_total_cost'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'week_start_date': weekStartDate.toIso8601String(),
        'meals': meals.map((m) => m.toJson()).toList(),
        'shopping_list': shoppingList,
        'actual_total_cost': actualTotalCost,
        'created_at': createdAt.toIso8601String(),
      };
}
