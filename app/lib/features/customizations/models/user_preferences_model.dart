/// Local representation of the `user_preferences` Supabase table.
class UserPreferences {
  final String? id;
  final String userId;

  /// 'omnivore' | 'vegetarian' | 'vegan' | 'pescatarian'
  final String dietType;

  /// 'lose_weight' | 'gain_weight' | 'maintain' | 'build_muscle'
  final String healthGoal;

  /// 'standard' | 'keto' | 'high_protein' | 'low_carb' | 'mediterranean'
  final String dietStyle;

  /// e.g. ['gluten', 'dairy', 'nuts']
  final List<String> allergies;

  final int householdSize;

  /// e.g. '$50-$100'
  final String budgetRange;

  final DateTime? updatedAt;

  const UserPreferences({
    this.id,
    required this.userId,
    required this.dietType,
    required this.healthGoal,
    required this.dietStyle,
    required this.allergies,
    required this.householdSize,
    required this.budgetRange,
    this.updatedAt,
  });

  /// Stable string used as the Claude cache key (SHA-256'd before storage).
  ///
  /// Sort allergies so the fingerprint is order-independent.
  String toFingerprintString() =>
      '$dietType|$healthGoal|$dietStyle|'
      '${(List<String>.from(allergies)..sort()).join(',')}|'
      '$householdSize|$budgetRange';

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      dietType: json['diet_type'] as String,
      healthGoal: json['health_goal'] as String,
      dietStyle: json['diet_style'] as String,
      allergies: List<String>.from(json['allergies'] as List? ?? []),
      householdSize: json['household_size'] as int,
      budgetRange: json['budget_range'] as String,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Serializes for Supabase upsert. Omits `id` when null (let DB assign it).
  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'diet_type': dietType,
        'health_goal': healthGoal,
        'diet_style': dietStyle,
        'allergies': allergies,
        'household_size': householdSize,
        'budget_range': budgetRange,
      };

  UserPreferences copyWith({
    String? id,
    String? userId,
    String? dietType,
    String? healthGoal,
    String? dietStyle,
    List<String>? allergies,
    int? householdSize,
    String? budgetRange,
    DateTime? updatedAt,
  }) {
    return UserPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dietType: dietType ?? this.dietType,
      healthGoal: healthGoal ?? this.healthGoal,
      dietStyle: dietStyle ?? this.dietStyle,
      allergies: allergies ?? this.allergies,
      householdSize: householdSize ?? this.householdSize,
      budgetRange: budgetRange ?? this.budgetRange,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
