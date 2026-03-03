import 'package:supabase_flutter/supabase_flutter.dart';

/// Local representation of an authenticated user.
///
/// Mirrors `auth.users` from Supabase but only exposes what the app needs.
class AppUser {
  final String id;
  final String email;
  final String name;
  final DateTime createdAt;
  final DateTime? lastNameChange;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
    this.lastNameChange,
  });

  factory AppUser.fromSupabaseUser(User user) {
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['name'] as String? ?? '',
      createdAt: DateTime.parse(user.createdAt),
      lastNameChange: user.userMetadata?['last_name_change'] != null
          ? DateTime.parse(user.userMetadata!['last_name_change'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'lastNameChange': lastNameChange?.toIso8601String(),
      };
}
