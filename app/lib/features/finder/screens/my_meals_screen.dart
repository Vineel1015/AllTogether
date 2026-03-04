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

class _SavedPlanCard extends StatefulWidget {
  final SavedPlan plan;
  const _SavedPlanCard({required this.plan});

  @override
  State<_SavedPlanCard> createState() => _SavedPlanCardState();
}

class _SavedPlanCardState extends State<_SavedPlanCard> {
  bool _isExpanded = false;
  final Set<String> _checkedItems = {};

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
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AllTogetherColors.mascotBlue.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Week of ${_formatDate(widget.plan.weekStartDate)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${widget.plan.shoppingList.length} Items',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (widget.plan.actualTotalCost != null)
                        Text(
                          '\$${widget.plan.actualTotalCost!.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (!_isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.plan.shoppingList.take(4).map((item) => Chip(
                  label: Text(item, style: const TextStyle(fontSize: 10)),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey[200]!),
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
            ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: widget.plan.shoppingList.map((item) {
                  final isChecked = _checkedItems.contains(item);
                  return CheckboxListTile(
                    value: isChecked,
                    title: Text(
                      item,
                      style: TextStyle(
                        decoration: isChecked ? TextDecoration.lineThrough : null,
                        color: isChecked ? Colors.grey : null,
                        fontSize: 14,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _checkedItems.add(item);
                        } else {
                          _checkedItems.remove(item);
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    activeColor: AllTogetherColors.mascotBlue,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}
