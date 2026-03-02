import 'package:supabase_flutter/supabase_flutter.dart';

/// Local representation of an authenticated user.
///
/// Mirrors `auth.users` from Supabase but only exposes what the app needs.
class AppUser {
  final String id;
  final String email;
  final String name;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
  });

  factory AppUser.fromSupabaseUser(User user) {
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['name'] as String? ?? '',
      createdAt: DateTime.parse(user.createdAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };
}
