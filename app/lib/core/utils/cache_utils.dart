import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/api_constants.dart';

/// Wraps a cached value with metadata for TTL expiry.
class CacheEntry<T> {
  final T data;
  final DateTime cachedAt;
  final Duration ttl;

  const CacheEntry({
    required this.data,
    required this.cachedAt,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().isAfter(cachedAt.add(ttl));

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) serializer) => {
        'data': serializer(data),
        'cachedAt': cachedAt.toIso8601String(),
        'ttlSeconds': ttl.inSeconds,
      };

  static CacheEntry<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) deserializer,
  ) =>
      CacheEntry(
        data: deserializer(json['data'] as Map<String, dynamic>),
        cachedAt: DateTime.parse(json['cachedAt'] as String),
        ttl: Duration(seconds: json['ttlSeconds'] as int),
      );
}

/// Returns the cached value for [key] in [box], or null if missing/expired.
Future<T?> getCached<T>(
  Box<String> box,
  String key,
  T Function(Map<String, dynamic>) fromJson,
) async {
  final raw = box.get(key);
  if (raw == null) return null;

  try {
    final entry = CacheEntry.fromJson<T>(
      jsonDecode(raw) as Map<String, dynamic>,
      fromJson,
    );
    if (entry.isExpired) {
      await box.delete(key);
      return null;
    }
    return entry.data;
  } catch (_) {
    await box.delete(key);
    return null;
  }
}

/// Serializes [data] and writes it to [box] under [key] with the given [ttl].
Future<void> setCache<T>(
  Box<String> box,
  String key,
  T data,
  Map<String, dynamic> Function(T) toJson,
  Duration ttl,
) async {
  final entry = CacheEntry<T>(
    data: data,
    cachedAt: DateTime.now(),
    ttl: ttl,
  );
  await box.put(key, jsonEncode(entry.toJson(toJson)));
}

/// Removes all expired entries from [box].
///
/// Run on startup in the background — never block the UI on this.
Future<void> evictExpiredEntries(Box<String> box) async {
  final keysToDelete = <dynamic>[];
  for (final key in box.keys) {
    final raw = box.get(key as String);
    if (raw == null) continue;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(decoded['cachedAt'] as String);
      final ttl = Duration(seconds: decoded['ttlSeconds'] as int);
      if (DateTime.now().isAfter(cachedAt.add(ttl))) {
        keysToDelete.add(key);
      }
    } catch (_) {
      keysToDelete.add(key);
    }
  }
  await box.deleteAll(keysToDelete);
}

/// Clears all active cache boxes on logout or account deletion.
Future<void> clearAllCaches() async {
  for (final name in [
    ApiConstants.mealCatalogCacheBox,
    ApiConstants.weeklyPlanCacheBox,
    ApiConstants.foodItemCacheBox,
    ApiConstants.placesCacheBox,
    ApiConstants.climatiqCacheBox,
  ]) {
    if (Hive.isBoxOpen(name)) {
      await Hive.box<String>(name).clear();
    }
  }
}
