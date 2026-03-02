import 'package:flutter/material.dart';

import '../models/meal_plan_model.dart';

/// Displays the full shopping list generated alongside the meal plan.
class ShoppingListWidget extends StatelessWidget {
  final List<ShoppingItem> items;

  const ShoppingListWidget({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No shopping list available.'),
        ),
      );
    }

    final total = items.fold(0.0, (sum, i) => sum + i.estimatedCost);

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) =>
                _ShoppingItemTile(item: items[index]),
          ),
        ),
        _TotalRow(total: total),
      ],
    );
  }
}

class _ShoppingItemTile extends StatelessWidget {
  final ShoppingItem item;

  const _ShoppingItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.item,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                if (item.quantity.isNotEmpty)
                  Text(
                    item.quantity,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (item.estimatedCost > 0)
            Text(
              '\$${item.estimatedCost.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final double total;

  const _TotalRow({required this.total});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Estimated Total',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}
