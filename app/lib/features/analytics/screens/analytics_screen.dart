import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../models/analytics_model.dart';
import '../providers/analytics_provider.dart';
import '../widgets/meal_score_card_widget.dart';
import '../widgets/nutrition_chart_widget.dart';
import '../widgets/score_badge_widget.dart';
import '../widgets/sustainability_card_widget.dart';

/// Analytics tab — visualizes nutrition and sustainability data from scanned receipts.
///
/// Data is derived purely from [receiptsProvider]; no additional API calls are made.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: analyticsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorBanner(
          message: 'Could not load analytics. Please try again.',
          onRetry: () => ref.invalidate(analyticsProvider),
        ),
        data: (analytics) => _AnalyticsBody(analytics: analytics),
      ),
    );
  }
}

// ── Analytics body ─────────────────────────────────────────────────────────────

class _AnalyticsBody extends StatelessWidget {
  final Analytics analytics;

  const _AnalyticsBody({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final nutrition = analytics.nutritionSummary;
    final sustainability = analytics.sustainabilitySummary;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Meal score section (always visible) ────────────────────────────
          Text('Your Meal Score', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          const MealScoreCardWidget(),

          if (analytics.isEmpty) ...[
            const SizedBox(height: 32),
            const _ReceiptEmptyState(),
          ] else ...[
            // ── Nutrition section ────────────────────────────────────────────
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            Text('Last 30 Days', style: textTheme.titleMedium),
            const SizedBox(height: 12),
            NutritionChartWidget(dailyNutrition: analytics.dailyNutrition),
            const SizedBox(height: 16),
            _NutritionSummaryRow(
              totalCalories: nutrition.totalCalories,
              avgCaloriesPerDay: nutrition.avgCaloriesPerDay,
              proteinG: nutrition.totalProteinG,
              carbsG: nutrition.totalCarbsG,
              fatG: nutrition.totalFatG,
              totalCost: nutrition.totalCost,
              avgCostPerDay: nutrition.avgCostPerDay,
            ),

            // ── Sustainability section ───────────────────────────────────────
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            Text('Sustainability', style: textTheme.titleMedium),
            const SizedBox(height: 12),
            ScoreBadgeWidget(summary: sustainability),
            const SizedBox(height: 12),
            SustainabilityCardWidget(summary: sustainability),
          ],
        ],
      ),
    );
  }
}

// ── Nutrition summary row ──────────────────────────────────────────────────────

class _NutritionSummaryRow extends StatelessWidget {
  final double totalCalories;
  final double avgCaloriesPerDay;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double totalCost;
  final double avgCostPerDay;

  const _NutritionSummaryRow({
    required this.totalCalories,
    required this.avgCaloriesPerDay,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.totalCost,
    required this.avgCostPerDay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatChip(label: 'Total cal', value: totalCalories.toStringAsFixed(0)),
            _StatChip(label: 'Avg/day', value: avgCaloriesPerDay.toStringAsFixed(0)),
            _StatChip(label: 'Protein', value: '${proteinG.toStringAsFixed(0)}g'),
            _StatChip(label: 'Carbs', value: '${carbsG.toStringAsFixed(0)}g'),
            _StatChip(label: 'Fat', value: '${fatG.toStringAsFixed(0)}g'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatChip(
              label: 'Total spent',
              value: '\$${totalCost.toStringAsFixed(2)}',
              color: Colors.green[700],
            ),
            const SizedBox(width: 32),
            _StatChip(
              label: 'Avg cost/day',
              value: '\$${avgCostPerDay.toStringAsFixed(2)}',
              color: Colors.green[700],
            ),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatChip({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold, color: color)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ── Receipt empty state ────────────────────────────────────────────────────────

class _ReceiptEmptyState extends StatelessWidget {
  const _ReceiptEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Scan receipts to see analytics',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Your nutrition and sustainability data will appear here.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
