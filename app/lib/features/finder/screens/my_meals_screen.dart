import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/saved_plan_model.dart';
import '../providers/weekly_plan_provider.dart';
import '../../../core/constants/brand_colors.dart';

class MyMealsScreen extends ConsumerWidget {
  const MyMealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real implementation, we'd have a savedPlansProvider. 
    // For now, we'll show a beautiful placeholder list.
    return Scaffold(
      appBar: AppBar(title: const Text('My Saved Plans')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Your Meal History',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _SavedPlanCard(
            plan: SavedPlan(
              id: '1',
              userId: 'me',
              weekStartDate: DateTime.now().subtract(const Duration(days: 7)),
              meals: [], // Mock
              shoppingList: ['Milk', 'Eggs', 'Spinach', 'Chicken'],
              actualTotalCost: 42.50,
              createdAt: DateTime.now(),
            ),
          ),
          const SizedBox(height: 16),
          _SavedPlanCard(
            plan: SavedPlan(
              id: '2',
              userId: 'me',
              weekStartDate: DateTime.now().subtract(const Duration(days: 14)),
              meals: [], // Mock
              shoppingList: ['Salmon', 'Quinoa', 'Avocado'],
              actualTotalCost: 31.20,
              createdAt: DateTime.now(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedPlanCard extends StatelessWidget {
  final SavedPlan plan;
  const _SavedPlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AllTogetherColors.mascotBlue.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Week of ${_formatDate(plan.weekStartDate)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (plan.actualTotalCost != null)
                  Text(
                    '\$${plan.actualTotalCost!.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Shopping List', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: plan.shoppingList.take(4).map((item) => Chip(
                    label: Text(item, style: const TextStyle(fontSize: 10)),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey[200]!),
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
                if (plan.shoppingList.length > 4)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('+ ${plan.shoppingList.length - 4} more items', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          TextButton(
            onPressed: () {},
            child: const Center(child: Text('Re-deal this Deck')),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}
