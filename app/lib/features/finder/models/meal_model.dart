import 'dart:convert';

/// A single meal in the catalog (preset or user-created).
class Meal {
  final String id;
  final String? userId; // null = preset
  final String name;
  final List<String> ingredients;
  final int calories;
  final int prepMinutes;
  final bool isPreset;

  const Meal({
    required this.id,
    this.userId,
    required this.name,
    required this.ingredients,
    required this.calories,
    required this.prepMinutes,
    this.isPreset = false,
  });

  // ── Factories ─────────────────────────────────────────────────────────────

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
        id: json['id'] as String,
        userId: json['user_id'] as String?,
        name: json['name'] as String,
        ingredients: List<String>.from(json['ingredients'] as List? ?? []),
        calories: (json['calories'] as num?)?.toInt() ?? 0,
        prepMinutes: (json['prep_minutes'] as num?)?.toInt() ?? 0,
        isPreset: json['is_preset'] as bool? ?? false,
      );

  /// Deserializes a row from the Supabase `meals` table.
  factory Meal.fromSupabaseJson(Map<String, dynamic> json) {
    final rawIngredients = json['ingredients'];
    List<String> ingredients;
    if (rawIngredients is List) {
      ingredients = List<String>.from(rawIngredients);
    } else if (rawIngredients is String) {
      // Supabase may return the array as a JSON string in some edge cases
      try {
        ingredients = List<String>.from(
            jsonDecode(rawIngredients) as List);
      } catch (_) {
        ingredients = [];
      }
    } else {
      ingredients = [];
    }

    return Meal(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      ingredients: ingredients,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      prepMinutes: (json['prep_minutes'] as num?)?.toInt() ?? 0,
      isPreset: json['user_id'] == null,
    );
  }

  // ── Serializers ───────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'ingredients': ingredients,
        'calories': calories,
        'prep_minutes': prepMinutes,
        'is_preset': isPreset,
      };

  /// Serializes for a Supabase insert into the `meals` table.
  Map<String, dynamic> toSupabaseJson() => {
        'user_id': userId,
        'name': name,
        'ingredients': ingredients,
        'calories': calories,
        'prep_minutes': prepMinutes,
      };

  Meal copyWith({
    String? id,
    String? userId,
    String? name,
    List<String>? ingredients,
    int? calories,
    int? prepMinutes,
    bool? isPreset,
  }) =>
      Meal(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        ingredients: ingredients ?? this.ingredients,
        calories: calories ?? this.calories,
        prepMinutes: prepMinutes ?? this.prepMinutes,
        isPreset: isPreset ?? this.isPreset,
      );
}
