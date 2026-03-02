import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/string_utils.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../customizations/screens/customizations_screen.dart';
import '../providers/meal_plan_provider.dart';
import '../providers/stores_provider.dart';
import '../widgets/meal_card_widget.dart';
import '../widgets/shopping_list_widget.dart';
import '../widgets/store_card_widget.dart';

/// The Finder tab — shows the current 7-day meal plan and shopping list.
///
/// Replaces [_FinderPlaceholder] from Session 1.
class FinderScreen extends ConsumerWidget {
  const FinderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(mealPlanNotifierProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finder'),
          actions: [
            _SettingsButton(),
            _RegenerateButton(planAsync: planAsync),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.restaurant_menu_outlined), text: 'Meals'),
              Tab(icon: Icon(Icons.shopping_cart_outlined), text: 'Shopping'),
            ],
          ),
        ),
        body: planAsync.when(
          loading: () => const LoadingIndicator(),
          error: (error, _) => _ErrorBody(error: error, ref: ref),
          data: (plan) {
            if (plan == null) return const _NoPreferencesBody();
            return _PlanBody(plan: plan);
          },
        ),
      ),
    );
  }
}

// ── AppBar actions ─────────────────────────────────────────────────────────

class _SettingsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.tune),
      tooltip: 'Preferences',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const CustomizationsScreen(isOnboarding: false),
        ),
      ),
    );
  }
}

class _RegenerateButton extends ConsumerWidget {
  final AsyncValue<dynamic> planAsync;

  const _RegenerateButton({required this.planAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = planAsync is AsyncLoading;
    return IconButton(
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh),
      tooltip: 'Regenerate meal plan',
      onPressed: isLoading
          ? null
          : () async {
              await ref.read(mealPlanNotifierProvider.notifier).regenerate();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Meal plan regenerated!')),
                );
              }
            },
    );
  }
}

// ── Body states ────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final Object error;
  final WidgetRef ref;

  const _ErrorBody({required this.error, required this.ref});

  @override
  Widget build(BuildContext context) {
    // Strip the leading "Exception: " wrapper added by the provider.
    // Provider throws Exception('[code] message'), so extract just the code.
    final raw = error.toString().replaceFirst('Exception: ', '');
    final codeMatch = RegExp(r'^\[([^\]]+)\]').firstMatch(raw);
    final code = codeMatch?.group(1);

    const knownCodes = {
      'offline', 'timeout', '429', '401', 'meal_plan_parse_error',
    };
    final message =
        code != null && knownCodes.contains(code) ? toUserMessage(code) : raw;

    // Auth errors: sign the user out so authStateProvider routes to LoginScreen.
    final onRetry = code == '401'
        ? () => Supabase.instance.client.auth.signOut()
        : () => ref.invalidate(mealPlanNotifierProvider);

    return ErrorBanner(message: message, onRetry: onRetry);
  }
}

class _NoPreferencesBody extends StatelessWidget {
  const _NoPreferencesBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.settings_outlined, size: 48),
            const SizedBox(height: 16),
            Text(
              'Set your preferences to generate a meal plan.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.tune),
              label: const Text('Set Preferences'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const CustomizationsScreen(isOnboarding: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanBody extends ConsumerWidget {
  final dynamic plan;

  const _PlanBody({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(storesProvider);

    return Column(
      children: [
        // Nearby stores strip (stubbed — hidden when empty)
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
                    itemBuilder: (_, i) =>
                        StoreCardWidget(store: stores[i]),
                  ),
                ),
          orElse: () => const SizedBox.shrink(),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            children: [
              // Meals tab
              ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                itemCount: plan.days.length,
                itemBuilder: (_, i) =>
                    MealCardWidget(dayPlan: plan.days[i]),
              ),
              // Shopping tab
              ShoppingListWidget(items: plan.shoppingList),
            ],
          ),
        ),
      ],
    );
  }
}
