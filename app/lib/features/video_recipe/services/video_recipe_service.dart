import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/video_recipe_model.dart';
import '../../../core/models/app_result.dart';

class VideoRecipeService {
  final SupabaseClient _supabase;

  VideoRecipeService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Sends a video URL or metadata to the AI processing service.
  Future<AppResult<VideoRecipe>> extractRecipeFromVideo(String videoUrl, {bool isRetry = false}) async {
    try {
      final response = await _supabase.functions.invoke(
        'process-video-recipe',
        body: {'video_url': videoUrl},
      );

      final dynamic rawData = response.data;
      if (rawData == null) {
        return const AppFailure('Failed to extract recipe from video.');
      }

      final Map<String, dynamic> data = rawData is String 
          ? jsonDecode(rawData) as Map<String, dynamic>
          : rawData as Map<String, dynamic>;
      
      // The Edge Function will return structured JSON
      return AppSuccess(VideoRecipe(
        id: data['id'] as String?,
        videoUrl: videoUrl,
        title: data['title'] as String? ?? 'Extracted Recipe',
        ingredients: List<String>.from(data['ingredients'] as List? ?? []),
        steps: List<String>.from(data['steps'] as List? ?? []),
        extractedText: List<String>.from(data['extracted_text'] as List? ?? []),
        createdAt: DateTime.now(),
      ));
    } on FunctionException catch (e) {
      final errorStr = e.details?.toString() ?? '';
      final is401 = e.status == 401 || errorStr.contains('401') || errorStr.contains('JWT');
      
      if (is401 && !isRetry) {
        // Try to refresh session once
        final refreshResult = await _supabase.auth.refreshSession();
        if (refreshResult.session != null) {
          // Retry the request with the new session
          return extractRecipeFromVideo(videoUrl, isRetry: true);
        }
      }
      
      return AppFailure('AI Processing Error: ${e.details ?? 'Unknown function error'}', code: e.status.toString());
    } catch (e) {
      return AppFailure('Unexpected error: $e');
    }
  }
}
