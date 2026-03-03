import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/video_recipe_model.dart';

class VideoRecipeNotifier extends AsyncNotifier<List<VideoRecipe>> {
  @override
  Future<List<VideoRecipe>> build() async {
    // Initial state: fetch previously processed recipes from database
    return [];
  }

  Future<void> processVideo(String videoUrl) async {
    state = const AsyncValue.loading();
    try {
      // 1. Upload video (placeholder)
      // 2. Call AI/ML Service (placeholder)
      // 3. Extract Text, Ingredients, and Steps (placeholder)
      
      final newRecipe = VideoRecipe(
        videoUrl: videoUrl,
        title: 'Extracted Recipe from Video',
        ingredients: ['Example Ingredient 1', 'Example Ingredient 2'],
        steps: ['Step 1: Prep', 'Step 2: Cook'],
        createdAt: DateTime.now(),
      );
      
      final currentList = state.valueOrNull ?? [];
      state = AsyncValue.data([...currentList, newRecipe]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final videoRecipeNotifierProvider =
    AsyncNotifierProvider<VideoRecipeNotifier, List<VideoRecipe>>(
  VideoRecipeNotifier.new,
);
