import 'package:flutter_test/flutter_test.dart';

import 'package:all_together/features/customizations/models/user_preferences_model.dart';

void main() {
  group('UserPreferences', () {
    const basePrefs = UserPreferences(
      userId: 'user-1',
      dietType: 'vegetarian',
      healthGoal: 'maintain',
      dietStyle: 'standard',
      allergies: ['gluten', 'dairy'],
      householdSize: 2,
      budgetRange: r'$50–$100',
    );

    // ── Fingerprint ─────────────────────────────────────────────────────────

    test('fingerprint is stable for identical preferences', () {
      const prefs2 = UserPreferences(
        userId: 'user-1',
        dietType: 'vegetarian',
        healthGoal: 'maintain',
        dietStyle: 'standard',
        allergies: ['gluten', 'dairy'],
        householdSize: 2,
        budgetRange: r'$50–$100',
      );

      expect(basePrefs.toFingerprintString(), prefs2.toFingerprintString());
    });

    test('fingerprint is order-independent for allergies', () {
      const sorted = UserPreferences(
        userId: 'user-1',
        dietType: 'vegetarian',
        healthGoal: 'maintain',
        dietStyle: 'standard',
        allergies: ['dairy', 'gluten'], // reversed
        householdSize: 2,
        budgetRange: r'$50–$100',
      );

      expect(basePrefs.toFingerprintString(), sorted.toFingerprintString());
    });

    test('fingerprint changes when diet type changes', () {
      final different = basePrefs.copyWith(dietType: 'vegan');
      expect(
        basePrefs.toFingerprintString(),
        isNot(different.toFingerprintString()),
      );
    });

    test('fingerprint changes when allergies change', () {
      final different = basePrefs.copyWith(allergies: ['nuts']);
      expect(
        basePrefs.toFingerprintString(),
        isNot(different.toFingerprintString()),
      );
    });

    test('empty allergies produce a stable fingerprint', () {
      const noAllergies = UserPreferences(
        userId: 'user-1',
        dietType: 'omnivore',
        healthGoal: 'maintain',
        dietStyle: 'standard',
        allergies: [],
        householdSize: 1,
        budgetRange: r'$50–$100',
      );

      expect(noAllergies.toFingerprintString(), contains('omnivore'));
      expect(noAllergies.toFingerprintString(), contains('||'));
    });

    // ── JSON round-trip ──────────────────────────────────────────────────────

    test('fromJson / toJson round-trips correctly', () {
      final json = {
        'id': 'pref-abc',
        'user_id': 'user-1',
        'diet_type': 'vegan',
        'health_goal': 'lose_weight',
        'diet_style': 'keto',
        'allergies': ['gluten'],
        'household_size': 3,
        'budget_range': r'$100–$150',
        'updated_at': '2025-06-01T12:00:00.000Z',
      };

      final prefs = UserPreferences.fromJson(json);

      expect(prefs.id, 'pref-abc');
      expect(prefs.userId, 'user-1');
      expect(prefs.dietType, 'vegan');
      expect(prefs.healthGoal, 'lose_weight');
      expect(prefs.dietStyle, 'keto');
      expect(prefs.allergies, ['gluten']);
      expect(prefs.householdSize, 3);
      expect(prefs.budgetRange, r'$100–$150');
      expect(prefs.updatedAt, isNotNull);

      final reJson = prefs.toJson();
      expect(reJson['diet_type'], 'vegan');
      expect(reJson['allergies'], ['gluten']);
    });

    test('toJson omits id when null', () {
      final json = basePrefs.toJson();
      expect(json.containsKey('id'), isFalse);
    });

    test('fromJson handles missing updated_at', () {
      final json = {
        'user_id': 'user-1',
        'diet_type': 'omnivore',
        'health_goal': 'maintain',
        'diet_style': 'standard',
        'allergies': <String>[],
        'household_size': 1,
        'budget_range': r'$50–$100',
      };

      final prefs = UserPreferences.fromJson(json);
      expect(prefs.updatedAt, isNull);
    });

    // ── copyWith ─────────────────────────────────────────────────────────────

    test('copyWith preserves unchanged fields', () {
      final copy = basePrefs.copyWith(householdSize: 4);

      expect(copy.dietType, basePrefs.dietType);
      expect(copy.healthGoal, basePrefs.healthGoal);
      expect(copy.householdSize, 4);
    });
  });
}
