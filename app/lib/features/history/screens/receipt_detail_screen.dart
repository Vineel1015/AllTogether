import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/food_item_model.dart';
import '../models/receipt_model.dart';
import '../widgets/nutrition_row_widget.dart';

/// Shows all line items for a [Receipt], with nutrition data where available.
class ReceiptDetailScreen extends StatelessWidget {
  final Receipt receipt;

  const ReceiptDetailScreen({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    final storeName = receipt.storeName?.isNotEmpty == true
        ? receipt.storeName!
        : 'Unknown store';
    final dateStr = DateFormat('MMM d, yyyy  h:mm a')
        .format(receipt.scannedAt.toLocal());

    return Scaffold(
      appBar: AppBar(title: Text(storeName)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateStr,
                    style: Theme.of(context).textTheme.bodySmall),
                if (receipt.totalAmount != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Total: \$${receipt.totalAmount!.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ],
            ),
          ),
          const Divider(),
          // ── Item list ──────────────────────────────────────────────────
          Expanded(
            child: receipt.items.isEmpty
                ? const Center(child: Text('No items parsed from this receipt.'))
                : ListView.separated(
                    itemCount: receipt.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = receipt.items[index];
                      return _ItemTile(
                        name: item.name,
                        price: item.price,
                        // FoodItem lookup in a real flow would come from a
                        // provider; for the detail view we use the matched ID
                        // as a placeholder until analytics wires this up.
                        foodItem: null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final String name;
  final double? price;
  final FoodItem? foodItem;

  const _ItemTile({
    required this.name,
    this.price,
    this.foodItem,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (price != null)
                Text(
                  '\$${price!.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
          if (foodItem != null) ...[
            const SizedBox(height: 4),
            NutritionRowWidget(item: foodItem!),
          ],
        ],
      ),
    );
  }
}
