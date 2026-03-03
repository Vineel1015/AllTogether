import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/loading_indicator.dart';
import '../models/meal_model.dart';
import '../models/preset_meals.dart';
import '../models/weekly_plan_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/finder_tab_provider.dart';
import '../providers/meal_catalog_provider.dart';
import '../providers/stores_provider.dart';
import '../providers/weekly_plan_provider.dart';
import '../widgets/create_meal_sheet.dart';
import '../widgets/meal_card_deck.dart';
import '../../../shared/mascot_widget.dart';
import '../../../core/constants/brand_colors.dart';

enum FinderPhase { picking, theHaul }

/// The Finder tab — Gamified meal selection with 'The Haul' grocery view.
class FinderScreen extends ConsumerStatefulWidget {
  const FinderScreen({super.key});

  @override
  ConsumerState<FinderScreen> createState() => _FinderScreenState();
}

class _FinderScreenState extends ConsumerState<FinderScreen> {
  FinderPhase _phase = FinderPhase.picking;
  final Set<String> _activeFilters = {'breakfast', 'lunch', 'dinner', 'snacks'};

  void _toggleFilter(String filter) {
    setState(() {
      if (_activeFilters.contains(filter)) {
        if (_activeFilters.length > 1) _activeFilters.remove(filter);
      } else {
        _activeFilters.add(filter);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(weeklyPlanNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const MascotWidget(size: 40),
            const SizedBox(width: 8),
            Text(_phase == FinderPhase.picking ? "What's Cookin?" : "The Haul"),
          ],
        ),
        actions: [
          if (_phase == FinderPhase.theHaul)
            TextButton.icon(
              onPressed: () => setState(() => _phase = FinderPhase.picking),
              icon: const Icon(Icons.shopping_basket),
              label: const Text('Go Shopping'),
            ),
        ],
      ),
      body: planAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => _ErrorBody(error: error, ref: ref),
        data: (plan) {
          if (_phase == FinderPhase.picking) {
            return Column(
              children: [
                _buildFilters(),
                Expanded(child: _buildPickingPhase()),
              ],
            );
          } else {
            return _TheHaulView(items: plan?.shoppingList ?? const []);
          }
        },
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _FilterChip(
            label: 'Breakfast',
            isActive: _activeFilters.contains('breakfast'),
            color: AllTogetherColors.breakfastBrown,
            onTap: () => _toggleFilter('breakfast'),
          ),
          _FilterChip(
            label: 'Lunch',
            isActive: _activeFilters.contains('lunch'),
            color: AllTogetherColors.lunchBlue,
            onTap: () => _toggleFilter('lunch'),
          ),
          _FilterChip(
            label: 'Dinner',
            isActive: _activeFilters.contains('dinner'),
            color: AllTogetherColors.dinnerOrange,
            onTap: () => _toggleFilter('dinner'),
          ),
          _FilterChip(
            label: 'Snacks',
            isActive: _activeFilters.contains('snacks'),
            color: AllTogetherColors.snackGreen,
            onTap: () => _toggleFilter('snacks'),
          ),
        ],
      ),
    );
  }

  Widget _buildPickingPhase() {
    final userMealsAsync = ref.watch(userMealsProvider);
    return userMealsAsync.when(
      data: (userMeals) {
        final allMeals = [...presetMeals, ...userMeals];
        // Filter the deck based on selection
        final filteredDeck = allMeals.where((m) {
          final id = m.id.toLowerCase();
          if (id.contains('_b') && _activeFilters.contains('breakfast')) return true;
          if (id.contains('_l') && _activeFilters.contains('lunch')) return true;
          if (id.contains('_d') && _activeFilters.contains('dinner')) return true;
          if (id.contains('_s') && _activeFilters.contains('snacks')) return true;
          return false;
        }).toList();

        final deck = List<Meal>.from(filteredDeck)..shuffle();
        
        return MealCardDeck(
          key: ValueKey(_activeFilters.join(',')), // Force rebuild on filter change
          meals: deck.take(15).toList(),
          maxSelections: 5,
          onSelectionComplete: (selectedMeals) async {
            await ref.read(weeklyPlanNotifierProvider.notifier).clearPlan();
            for (final meal in selectedMeals) {
              await ref.read(weeklyPlanNotifierProvider.notifier).addMeal(meal);
            }
            if (mounted) {
              setState(() => _phase = FinderPhase.theHaul);
            }
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(child: Text('Error loading deck: $e')),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(color: isActive ? Colors.white : color, fontSize: 12, fontWeight: FontWeight.bold)),
        selected: isActive,
        onSelected: (_) => onTap(),
        selectedColor: color,
        backgroundColor: Colors.white,
        shape: StadiumBorder(side: BorderSide(color: color)),
      ),
    );
  }
}

class _TheHaulView extends StatelessWidget {
  final List<String> items;

  const _TheHaulView({required this.items});

  void _exportToClipboard(BuildContext context) {
    final formattedList = StringBuffer('🛒 The Haul - AllTogether Shopping List\n\n');
    for (final item in items) {
      formattedList.writeln('• ${item[0].toUpperCase()}${item.substring(1)}');
    }
    Clipboard.setData(ClipboardData(text: formattedList.toString())).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Haul copied to clipboard!')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Your haul is empty! Go back and pick some cards.'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text('${items.length} Items found', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () => _exportToClipboard(context),
                tooltip: 'Copy List',
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => _HaulItemCard(item: items[index]),
          ),
        ),
      ],
    );
  }
}

class _HaulItemCard extends StatelessWidget {
  final String item;
  const _HaulItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.green[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          children: [
            const Icon(Icons.check_box_outline_blank, size: 18, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item[0].toUpperCase() + item.substring(1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final Object error;
  final WidgetRef ref;

  const _ErrorBody({required this.error, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Could not load your meal deck.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              onPressed: () => ref.invalidate(weeklyPlanNotifierProvider),
            ),
          ],
        ),
      ),
    );
  }
}
