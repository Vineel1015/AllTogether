import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/video_recipe_provider.dart';
import '../models/video_recipe_model.dart';
import '../../finder/providers/weekly_plan_provider.dart';
import '../../auth/providers/auth_provider.dart';

class VideoRecipeScreen extends ConsumerStatefulWidget {
  const VideoRecipeScreen({super.key});

  @override
  ConsumerState<VideoRecipeScreen> createState() => _VideoRecipeScreenState();
}

class _VideoRecipeScreenState extends ConsumerState<VideoRecipeScreen> {
  final _videoUrlController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _processVideo() async {
    final url = _videoUrlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isProcessing = true);
    
    await ref.read(videoRecipeNotifierProvider.notifier).processVideo(url);
    
    if (mounted) {
      setState(() => _isProcessing = false);
      _videoUrlController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video processed successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoRecipesAsync = ref.watch(videoRecipeNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Video to Recipe')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Extract a Recipe from Video',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter a video URL (TikTok, Instagram, YouTube) to automatically extract ingredients and steps using Gemini AI.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _videoUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Video URL',
                        hintText: 'https://www.tiktok.com/@chef/video/123...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _isProcessing ? null : _processVideo,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(_isProcessing ? 'AI is analyzing video...' : 'Extract Recipe with Gemini'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: videoRecipesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) {
                final errorStr = e.toString();
                final is401 = errorStr.contains('401') || errorStr.contains('JWT');
                
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          is401 
                            ? 'Your session has expired. Please sign in again.' 
                            : 'Error: $e', 
                          textAlign: TextAlign.center, 
                          style: const TextStyle(color: Colors.red),
                        ),
                        if (is401) ...[
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => ref.read(authServiceProvider).signOut(),
                            icon: const Icon(Icons.login),
                            label: const Text('Sign In'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
              data: (recipes) => recipes.isEmpty
                  ? const Center(
                      child: Text('No extracted recipes yet. Start by entering a video URL!'),
                    )
                  : ListView.builder(
                      itemCount: recipes.length,
                      itemBuilder: (context, index) => _RecipeCard(recipe: recipes[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeCard extends ConsumerWidget {
  final VideoRecipe recipe;

  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(recipe.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Extracted on ${_formatDate(recipe.createdAt)}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (recipe.extractedText.isNotEmpty) ...[
                  const Text('Video Captions/Text', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: recipe.extractedText.map((text) => Chip(
                      label: Text(text, style: const TextStyle(fontSize: 10)),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text('Ingredients', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...recipe.ingredients.map((ing) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(ing)),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                const Text('Steps', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...recipe.steps.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text('${entry.key + 1}. ${entry.value}'),
                )),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    final userId = ref.read(authServiceProvider).currentUser?.id;
                    if (userId == null) return;
                    
                    final meal = recipe.toMeal(userId);
                    await ref.read(weeklyPlanNotifierProvider.notifier).addMeal(meal);
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to My Meals & Shopping List!')),
                      );
                    }
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Add to My Meals & Shopping List'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
