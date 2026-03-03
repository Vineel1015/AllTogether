import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../widgets/meal_catalog_card_widget.dart';
import '../widgets/store_card_widget.dart';
import '../../recipe_scraper/screens/recipe_scraper_screen.dart';

/// The Finder tab — DoorDash-style meal catalog with an "In Your Plan" strip.
class FinderScreen extends ConsumerStatefulWidget {
  const FinderScreen({super.key});

  @override
  ConsumerState<FinderScreen> createState() => _FinderScreenState();
}

class _FinderScreenState extends ConsumerState<FinderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: ref.read(finderTabProvider),
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      ref.read(finderTabProvider.notifier).state = _tabController.index;
    });
  }

  @override
  void didUpdateWidget(FinderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final providerIndex = ref.read(finderTabProvider);
    if (_tabController.index != providerIndex) {
      _tabController.animateTo(providerIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for changes from the sidebar
    ref.listen<int>(finderTabProvider, (previous, next) {
      if (_tabController.index != next) {
        _tabController.animateTo(next);
      }
    });

    final planAsync = ref.watch(weeklyPlanNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: 'Scrape from Web',
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => const RecipeScraperScreen(),
              ).then((_) => ref.invalidate(userMealsProvider));
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create meal',
            onPressed: () {
              final container = ProviderScope.containerOf(context);
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => UncontrolledProviderScope(
                  container: container,
                  child: const CreateMealSheet(),
                ),
              ).then((_) => ref.invalidate(userMealsProvider));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant_menu_outlined), text: 'Plan'),
            Tab(icon: Icon(Icons.shopping_cart_outlined), text: 'Shopping'),
          ],
        ),
      ),
      body: planAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => _ErrorBody(error: error, ref: ref),
        data: (plan) => TabBarView(
          controller: _tabController,
          children: [
            _CatalogTab(plan: plan),
            _ShoppingTab(items: plan?.shoppingList ?? const []),
          ],
        ),
      ),
    );
  }
}

// ── Error body ───────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final Object error;
  final WidgetRef ref;

  const _ErrorBody({required this.error, required this.ref});

  @override
  Widget build(BuildContext context) {
    final raw = error.toString().replaceFirst('Exception: ', '');
    final codeMatch = RegExp(r'^\[([^\]]+)\]').firstMatch(raw);
    final code = codeMatch?.group(1);
    final is401 = code == '401' || code == 'JWT expired';

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
              is401
                  ? 'Your session has expired. Please sign in again.'
                  : 'Could not load your meal plan.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: Icon(is401 ? Icons.login : Icons.refresh),
              label: Text(is401 ? 'Sign In' : 'Try Again'),
              onPressed: is401
                  ? () => ref.read(authServiceProvider).signOut()
                  : () => ref.invalidate(weeklyPlanNotifierProvider),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Catalog tab (main content) ────────────────────────────────────────────────

class _CatalogTab extends ConsumerWidget {
  final WeeklyPlan? plan;

  const _CatalogTab({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planMealIds = plan?.meals.map((m) => m.id).toSet() ?? {};
    final storesAsync = ref.watch(storesProvider);
    final userMealsAsync = ref.watch(userMealsProvider);

    final breakfast =
        presetMeals.where((m) => m.id.startsWith('preset_b')).toList();
    final lunch =
        presetMeals.where((m) => m.id.startsWith('preset_l')).toList();
    final dinner =
        presetMeals.where((m) => m.id.startsWith('preset_d')).toList();
    final snacks =
        presetMeals.where((m) => m.id.startsWith('preset_s')).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // ── Nearby stores strip ─────────────────────────────────────
        storesAsync.maybeWhen(
          data: (stores) => stores.isEmpty
              ? const SizedBox.shrink()
              : SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: stores.length,
                    itemBuilder: (_, i) => StoreCardWidget(store: stores[i]),
                  ),
                ),
          orElse: () => const SizedBox.shrink(),
        ),

        // ── In Your Plan strip ──────────────────────────────────────
        if (plan case final p? when p.meals.isNotEmpty)
          _InYourPlanSection(meals: p.meals),

        // ── Category rows ────────────────────────────────────────────
        _CategoryRow(
          title: 'Breakfast',
          meals: breakfast,
          planMealIds: planMealIds,
        ),
        _CategoryRow(
          title: 'Lunch',
          meals: lunch,
          planMealIds: planMealIds,
        ),
        _CategoryRow(
          title: 'Dinner',
          meals: dinner,
          planMealIds: planMealIds,
        ),
        _CategoryRow(
          title: 'Snacks',
          meals: snacks,
          planMealIds: planMealIds,
        ),

        // ── My Meals ─────────────────────────────────────────────────
        userMealsAsync.maybeWhen(
          data: (userMeals) {
            if (userMeals.isEmpty) return const SizedBox.shrink();
            return _CategoryRow(
              title: 'My Meals',
              meals: userMeals,
              planMealIds: planMealIds,
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ── "In Your Plan" horizontal chip strip ─────────────────────────────────────

class _InYourPlanSection extends ConsumerWidget {
  final List<Meal> meals;

  const _InYourPlanSection({required this.meals});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                'In Your Plan',
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${meals.length}',
                  style: textTheme.labelSmall
                      ?.copyWith(color: colorScheme.onPrimary),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    ref.read(weeklyPlanNotifierProvider.notifier).clearPlan(),
                child: Text(
                  'Clear all',
                  style: TextStyle(
                      color: colorScheme.error, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: meals.length,
            itemBuilder: (_, i) => _PlanChip(meal: meals[i]),
          ),
        ),
        const SizedBox(height: 8),
        Divider(height: 1, color: colorScheme.outlineVariant),
      ],
    );
  }
}

class _PlanChip extends ConsumerWidget {
  final Meal meal;

  const _PlanChip({required this.meal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            meal.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => ref
                .read(weeklyPlanNotifierProvider.notifier)
                .removeMeal(meal.id),
            child: Icon(Icons.close,
                size: 14, color: colorScheme.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

// ── Category horizontal scroll row ───────────────────────────────────────────

class _CategoryRow extends ConsumerWidget {
  final String title;
  final List<Meal> meals;
  final Set<String> planMealIds;

  const _CategoryRow({
    required this.title,
    required this.meals,
    required this.planMealIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        // Horizontal card scroll
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: meals.length,
            itemBuilder: (_, i) {
              final meal = meals[i];
              final inPlan = planMealIds.contains(meal.id);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: MealCatalogCard(
                  meal: meal,
                  isInPlan: inPlan,
                  onAdd: () => ref
                      .read(weeklyPlanNotifierProvider.notifier)
                      .addMeal(meal),
                  onRemove: inPlan
                      ? () => ref
                          .read(weeklyPlanNotifierProvider.notifier)
                          .removeMeal(meal.id)
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Shopping tab ─────────────────────────────────────────────────────────────

class _ShoppingTab extends StatelessWidget {
  final List<String> items;

  const _ShoppingTab({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_cart_outlined,
                  size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Add meals to your plan to\nauto-generate a shopping list.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(Icons.check_box_outline_blank,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _capitalize(items[i]),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
