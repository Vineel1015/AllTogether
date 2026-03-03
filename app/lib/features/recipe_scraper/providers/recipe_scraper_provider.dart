import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/app_result.dart';
import '../models/scraped_recipe_model.dart';
import '../services/recipe_scraper_service.dart';

final recipeScraperServiceProvider = Provider<RecipeScraperService>((ref) {
  return RecipeScraperService();
});

class RecipeScraperNotifier extends AsyncNotifier<ScrapedRecipe?> {
  @override
  Future<ScrapedRecipe?> build() async {
    return null;
  }

  Future<void> scrapeUrl(String url) async {
    state = const AsyncValue.loading();
    
    final service = ref.read(recipeScraperServiceProvider);
    final result = await service.scrapeRecipe(url);

    switch (result) {
      case AppSuccess(:final data):
        state = AsyncValue.data(data);
      case AppFailure(:final message):
        state = AsyncValue.error(message, StackTrace.current);
    }
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}

final recipeScraperProvider =
    AsyncNotifierProvider<RecipeScraperNotifier, ScrapedRecipe?>(
  RecipeScraperNotifier.new,
);
