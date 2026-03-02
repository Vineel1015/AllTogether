import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/food_item_model.dart';
import '../models/receipt_item_model.dart';
import '../models/receipt_model.dart';
import '../providers/receipt_provider.dart';
import '../widgets/nutrition_row_widget.dart';

/// Shows all line items for a [Receipt], with nutrition data where available.
class ReceiptDetailScreen extends ConsumerWidget {
  final Receipt receipt;

  const ReceiptDetailScreen({super.key, required this.receipt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                ? const Center(
                    child: Text('No items parsed from this receipt.'))
                : ListView.separated(
                    itemCount: receipt.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = receipt.items[index];
                      return _ItemTile(item: item, ref: ref);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final ReceiptItem item;
  final WidgetRef ref;

  const _ItemTile({required this.item, required this.ref});

  @override
  Widget build(BuildContext context) {
    final foodAsync = ref.watch(foodItemByNameProvider(item.name));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (item.price != null)
                Text(
                  '\$${item.price!.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
          foodAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (FoodItem? foodItem) => foodItem != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: NutritionRowWidget(item: foodItem),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
