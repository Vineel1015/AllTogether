import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/recipe_scraper_provider.dart';
import '../../finder/providers/weekly_plan_provider.dart';
import '../../auth/providers/auth_provider.dart';

class RecipeScraperScreen extends ConsumerStatefulWidget {
  const RecipeScraperScreen({super.key});

  @override
  ConsumerState<RecipeScraperScreen> createState() => _RecipeScraperScreenState();
}

class _RecipeScraperScreenState extends ConsumerState<RecipeScraperScreen> {
  final _urlController = TextEditingController();
  final Set<int> _verifiedIngredients = {};
  bool _isAddingToPlan = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _scrape() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    
    _verifiedIngredients.clear();
    await ref.read(recipeScraperProvider.notifier).scrapeUrl(url);
  }

  Future<void> _confirmAndAdd() async {
    final recipe = ref.read(recipeScraperProvider).value;
    if (recipe == null) return;

    if (_verifiedIngredients.length < recipe.ingredients.length) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Unverified Ingredients'),
          content: const Text('You haven't verified all ingredients. Are you sure they are factual and make sense?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Go Back')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Add Anyway')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isAddingToPlan = true);
    
    final userId = ref.read(authServiceProvider).currentUser?.id;
    if (userId != null) {
      await ref.read(weeklyPlanNotifierProvider.notifier).addMeal(recipe.toMeal(userId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe verified and added to My Meals!')),
        );
        ref.read(recipeScraperProvider.notifier).clear();
        _urlController.clear();
      }
    }
    
    setState(() => _isAddingToPlan = false);
  }

  @override
  Widget build(BuildContext context) {
    final scraperState = ref.watch(recipeScraperProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Website Recipe Scraper')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Import from Web',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter a URL from any cooking website. AI will find the recipe and you can verify the details.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'https://example.com/healthy-recipe',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _scrape,
                ),
              ),
              onSubmitted: (_) => _scrape(),
            ),
            const SizedBox(height: 32),
            scraperState.when(
              data: (recipe) => recipe == null 
                  ? const _EmptyScraperState() 
                  : _buildRecipeDetails(recipe),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeDetails(dynamic recipe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[100]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipe.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (recipe.sourceName != null) ...[
                    Text('Source: ${recipe.sourceName}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(width: 12),
                  ],
                  Icon(Icons.timer_outlined, size: 14, color: Colors.blueGrey[600]),
                  const SizedBox(width: 4),
                  Text('${recipe.prepMinutes}m', style: TextStyle(color: Colors.blueGrey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Icon(Icons.local_fire_department_outlined, size: 14, color: Colors.orange[700]),
                  const SizedBox(width: 4),
                  Text('${recipe.calories} kcal', style: TextStyle(color: Colors.orange[700], fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Row(
          children: [
            Icon(Icons.fact_check_outlined, size: 20),
            SizedBox(width: 8),
            Text(
              'Verify Ingredients',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const Text(
          'Please tap the ingredients that are factual and correct.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ...List.generate(recipe.ingredients.length, (index) {
          final isVerified = _verifiedIngredients.contains(index);
          return CheckboxListTile(
            title: Text(recipe.ingredients[index]),
            value: isVerified,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _verifiedIngredients.add(index);
                } else {
                  _verifiedIngredients.remove(index);
                }
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
          );
        }),
        const SizedBox(height: 24),
        const Text(
          'Preparation Guide',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...recipe.steps.asMap().entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text('${entry.key + 1}. ${entry.value}'),
        )),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: _isAddingToPlan ? null : _confirmAndAdd,
          icon: _isAddingToPlan 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_circle),
          label: const Text('Verify & Add to My Meals'),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _EmptyScraperState extends StatelessWidget {
  const _EmptyScraperState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        children: [
          Icon(Icons.language, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Ready to scrape healthy meals', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
