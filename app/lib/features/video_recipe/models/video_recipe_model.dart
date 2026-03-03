import '../../finder/models/meal_model.dart';

class VideoRecipe {
  final String? id;
  final String videoUrl;
  final String title;
  final List<String> extractedText;
  final List<String> ingredients;
  final List<String> steps;
  final DateTime createdAt;

  const VideoRecipe({
    this.id,
    required this.videoUrl,
    required this.title,
    this.extractedText = const [],
    this.ingredients = const [],
    this.steps = const [],
    required this.createdAt,
  });

  /// Converts the video recipe to a standard [Meal] object to be added to My Meals.
  Meal toMeal(String userId) {
    return Meal(
      id: id ?? 'vr_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      name: title,
      ingredients: ingredients,
      calories: 0, // Calories would need manual entry or additional AI processing
      prepMinutes: 0, // Prep time would need manual entry
      isPreset: false,
    );
  }

  factory VideoRecipe.fromJson(Map<String, dynamic> json) {
    return VideoRecipe(
      id: json['id'] as String?,
      videoUrl: json['video_url'] as String,
      title: json['title'] as String,
      extractedText: List<String>.from(json['extracted_text'] as List? ?? []),
      ingredients: List<String>.from(json['ingredients'] as List? ?? []),
      steps: List<String>.from(json['steps'] as List? ?? []),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'video_url': videoUrl,
        'title': title,
        'extracted_text': extractedText,
        'ingredients': ingredients,
        'steps': steps,
        'created_at': createdAt.toIso8601String(),
      };
}
