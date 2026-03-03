import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/scraped_recipe_model.dart';
import '../../../core/models/app_result.dart';

class RecipeScraperService {
  final SupabaseClient _supabase;

  RecipeScraperService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  Future<AppResult<ScrapedRecipe>> scrapeRecipe(String url) async {
    try {
      final response = await _supabase.functions.invoke(
        'scrape-recipe',
        body: {'url': url},
      );

      final dynamic rawData = response.data;
      if (rawData == null) {
        return const AppFailure('Failed to scrape recipe from website.');
      }

      final Map<String, dynamic> data = rawData is String 
          ? jsonDecode(rawData) as Map<String, dynamic>
          : rawData as Map<String, dynamic>;
      
      if (data.containsKey('error')) {
        return AppFailure(data['error'] as String);
      }
      
      return AppSuccess(ScrapedRecipe.fromJson({
        ...data,
        'url': url,
        'created_at': DateTime.now().toIso8601String(),
      }));
    } on FunctionException catch (e) {
      return AppFailure('Scraping Error: ${e.details ?? 'Unknown function error'}', code: e.status.toString());
    } catch (e) {
      return AppFailure('Unexpected error: $e');
    }
  }
}
