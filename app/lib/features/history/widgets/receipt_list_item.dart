import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/receipt_model.dart';
import '../screens/receipt_detail_screen.dart';

/// Card for a single [Receipt] entry in the history list.
///
/// Shows date, store name, item count, and total amount.
/// Tapping navigates to [ReceiptDetailScreen].
class ReceiptListItem extends StatelessWidget {
  final Receipt receipt;

  const ReceiptListItem({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('MMM d, yyyy  h:mm a').format(receipt.scannedAt.toLocal());
    final storeName = receipt.storeName?.isNotEmpty == true
        ? receipt.storeName!
        : 'Unknown store';
    final itemCount = receipt.items.length;
    final total = receipt.totalAmount;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.receipt_long),
        title: Text(storeName),
        subtitle: Text(
          '$dateStr  •  $itemCount item${itemCount == 1 ? '' : 's'}',
        ),
        trailing: total != null
            ? Text(
                '\$${total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium,
              )
            : null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReceiptDetailScreen(receipt: receipt),
          ),
        ),
      ),
    );
  }
}
