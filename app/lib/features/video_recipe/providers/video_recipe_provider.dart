import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/app_result.dart';
import '../models/video_recipe_model.dart';
import '../services/video_recipe_service.dart';

final videoRecipeServiceProvider = Provider<VideoRecipeService>((ref) {
  return VideoRecipeService();
});

class VideoRecipeNotifier extends AsyncNotifier<List<VideoRecipe>> {
  @override
  Future<List<VideoRecipe>> build() async {
    // Initial state: fetch previously processed recipes from database
    return [];
  }

  Future<void> processVideo(String videoUrl) async {
    state = const AsyncValue.loading();
    
    final service = ref.read(videoRecipeServiceProvider);
    final result = await service.extractRecipeFromVideo(videoUrl);

    switch (result) {
      case AppSuccess(:final data):
        final currentList = state.valueOrNull ?? [];
        state = AsyncValue.data([...currentList, data]);
      case AppFailure(:final message):
        state = AsyncValue.error(message, StackTrace.current);
    }
  }
}

final videoRecipeNotifierProvider =
    AsyncNotifierProvider<VideoRecipeNotifier, List<VideoRecipe>>(
  VideoRecipeNotifier.new,
);
