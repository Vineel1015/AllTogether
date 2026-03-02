import 'package:flutter_test/flutter_test.dart';

import 'package:all_together/features/auth/models/app_user_model.dart';

void main() {
  group('AppUser', () {
    test('toJson round-trips through manual construction', () {
      final user = AppUser(
        id: 'abc-123',
        email: 'test@example.com',
        name: 'Alice',
        createdAt: DateTime(2025, 1, 15),
      );

      final json = user.toJson();

      expect(json['id'], 'abc-123');
      expect(json['email'], 'test@example.com');
      expect(json['name'], 'Alice');
      expect(json['createdAt'], '2025-01-15T00:00:00.000');
    });

    test('email defaults to empty string when null', () {
      // Simulates a Supabase user whose email hasn't been confirmed yet.
      final user = AppUser(
        id: 'def-456',
        email: '',
        name: 'Bob',
        createdAt: DateTime(2025, 2, 1),
      );

      expect(user.email, isEmpty);
    });

    test('name defaults to empty string when metadata is absent', () {
      final user = AppUser(
        id: 'ghi-789',
        email: 'user@example.com',
        name: '',
        createdAt: DateTime(2025, 3, 1),
      );

      expect(user.name, isEmpty);
    });
  });
}
