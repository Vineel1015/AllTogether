import '../../finder/models/meal_model.dart';

class ScrapedRecipe {
  final String? id;
  final String url;
  final String title;
  final List<String> ingredients;
  final List<String> steps;
  final String? sourceName;
  final int prepMinutes;
  final int calories;
  final DateTime createdAt;

  const ScrapedRecipe({
    this.id,
    required this.url,
    required this.title,
    this.ingredients = const [],
    this.steps = const [],
    this.sourceName,
    this.prepMinutes = 0,
    this.calories = 0,
    required this.createdAt,
  });

  Meal toMeal(String userId) {
    return Meal(
      id: id ?? 'scrape_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      name: title,
      ingredients: ingredients,
      calories: calories,
      prepMinutes: prepMinutes,
      isPreset: false,
    );
  }

  factory ScrapedRecipe.fromJson(Map<String, dynamic> json) {
    return ScrapedRecipe(
      id: json['id'] as String?,
      url: json['url'] as String? ?? '',
      title: json['title'] as String? ?? 'Unnamed Recipe',
      ingredients: List<String>.from(json['ingredients'] as List? ?? []),
      steps: List<String>.from(json['steps'] as List? ?? []),
      sourceName: json['source_name'] as String?,
      prepMinutes: (json['prep_minutes'] as num?)?.toInt() ?? 0,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'title': title,
        'ingredients': ingredients,
        'steps': steps,
        'source_name': sourceName,
        'created_at': createdAt.toIso8601String(),
      };
}
