import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/api_constants.dart';
import '../core/models/app_result.dart';
import '../features/customizations/models/user_preferences_model.dart';

/// Generates 7-day meal plans via the Supabase Edge Function
/// `generate-meal-plan`, which calls the Gemini API server-side.
class GeminiService {
  final SupabaseClient? _supabaseOverride;

  GeminiService({SupabaseClient? supabase}) : _supabaseOverride = supabase;

  SupabaseClient get _supabase => _supabaseOverride ?? Supabase.instance.client;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Generates a 7-day meal plan for [prefs] via the Edge Function.
  Future<AppResult<Map<String, dynamic>>> generateMealPlan(
    UserPreferences prefs,
  ) async {
    return _withRetry(() => _invokeEdgeFunction(prefs));
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<AppResult<Map<String, dynamic>>> _invokeEdgeFunction(
    UserPreferences prefs,
  ) async {
    try {
      debugPrint('[GeminiService] Invoking Edge Function: ${ApiConstants.mealPlanEdgeFunction}');
      final response = await _supabase.functions.invoke(
        ApiConstants.mealPlanEdgeFunction,
        body: {'preferences': _prefsToJson(prefs)},
      );

      final data = response.data;

      if (data == null) {
        debugPrint('[GeminiService] Edge Function returned null data.');
        return const AppFailure(
          'Empty response from meal plan service.',
          code: 'meal_plan_parse_error',
        );
      }

      // Edge Function error field
      if (data is Map && data.containsKey('error')) {
        final errMsg = data['error'].toString();
        debugPrint('[GeminiService] Edge Function error field: $errMsg');
        return AppFailure(
          errMsg,
          code: _codeFromEdgeError(errMsg),
          isRetryable: true,
        );
      }

      // Extract textResult wrapped in our content format
      return _extractMealPlanJson(data as Map<String, dynamic>);
    } on FunctionException catch (e) {
      debugPrint('[GeminiService] FunctionException: status=${e.status}, details=${e.details}');
      final status = (e.status is int) ? e.status as int : 500;
      final isRateLimit = status == 429;
      return AppFailure(
        'Meal plan service error ($status).',
        code: status == 401 ? 'service_auth_error' : '$status',
        isRetryable: isRateLimit || status >= 500,
      );
    } catch (e) {
      debugPrint('[GeminiService] Unexpected error: $e');
      return AppFailure('Unexpected error: $e');
    }
  }

  AppResult<Map<String, dynamic>> _extractMealPlanJson(
    Map<String, dynamic> envelope,
  ) {
    try {
      final content = envelope['content'] as List?;
      if (content == null || content.isEmpty) {
        return const AppFailure(
          'Empty content from Gemini.',
          code: 'meal_plan_parse_error',
        );
      }
      final text =
          (content.first as Map<String, dynamic>)['text'] as String? ?? '';
      return _parseJsonText(text);
    } catch (e) {
      debugPrint('[GeminiService] Parse error: $e');
      return const AppFailure(
        'Could not parse meal plan response.',
        code: 'meal_plan_parse_error',
      );
    }
  }

  AppResult<Map<String, dynamic>> _parseJsonText(String text) {
    try {
      return AppSuccess(jsonDecode(text.trim()) as Map<String, dynamic>);
    } catch (_) {}

    final match = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (match != null) {
      try {
        return AppSuccess(
            jsonDecode(match.group(0)!) as Map<String, dynamic>);
      } catch (_) {}
    }

    return const AppFailure(
      'Could not extract JSON from Gemini response.',
      code: 'meal_plan_parse_error',
    );
  }

  Future<AppResult<T>> _withRetry<T>(
    Future<AppResult<T>> Function() call, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    var delay = initialDelay;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final result = await call();
      if (result is AppSuccess<T>) return result;

      final failure = result as AppFailure<T>;
      if (!failure.isRetryable || attempt == maxAttempts) return result;

      debugPrint(
        '[GeminiService] Attempt $attempt failed (${failure.code}). '
        'Retrying in ${delay.inSeconds}s…',
      );
      await Future.delayed(delay);
      delay *= 2;
    }

    return const AppFailure('Max retries exceeded.', code: 'max_retries');
  }

  Map<String, dynamic> _prefsToJson(UserPreferences prefs) => {
        'dietType': prefs.dietType,
        'healthGoal': prefs.healthGoal,
        'dietStyle': prefs.dietStyle,
        'allergies': prefs.allergies,
        'householdSize': prefs.householdSize,
        'budgetRange': prefs.budgetRange,
      };

  String _codeFromEdgeError(String msg) {
    if (msg.contains('429')) return '429';
    if (msg.contains('401')) return 'service_auth_error';
    if (msg.contains('not configured')) return 'service_config_error';
    return 'edge_error';
  }
}
