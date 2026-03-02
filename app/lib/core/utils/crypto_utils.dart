import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Returns the lowercase hex SHA-256 digest of [input].
///
/// Used to generate stable cache keys from UserPreferences fingerprints.
String sha256ofString(String input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
