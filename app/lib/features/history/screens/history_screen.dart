import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/string_utils.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../models/receipt_model.dart';
import '../providers/receipt_provider.dart';
import '../widgets/receipt_list_item.dart';
import 'scan_screen.dart';

enum _ReceiptSort {
  newestFirst,
  oldestFirst,
  highestAmount,
  lowestAmount,
}

extension on _ReceiptSort {
  String get label => switch (this) {
        _ReceiptSort.newestFirst => 'Newest first',
        _ReceiptSort.oldestFirst => 'Oldest first',
        _ReceiptSort.highestAmount => 'Highest amount',
        _ReceiptSort.lowestAmount => 'Lowest amount',
      };
}

/// History tab — lists all scanned receipts for the current user.
///
/// FAB opens [ScanScreen]. Supports sorting and swipe-to-delete.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _ReceiptSort _sort = _ReceiptSort.newestFirst;

  List<Receipt> _sorted(List<Receipt> receipts) {
    final copy = List<Receipt>.from(receipts);
    switch (_sort) {
      case _ReceiptSort.newestFirst:
        copy.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
      case _ReceiptSort.oldestFirst:
        copy.sort((a, b) => a.scannedAt.compareTo(b.scannedAt));
      case _ReceiptSort.highestAmount:
        copy.sort(
            (a, b) => (b.totalAmount ?? 0).compareTo(a.totalAmount ?? 0));
      case _ReceiptSort.lowestAmount:
        copy.sort(
            (a, b) => (a.totalAmount ?? 0).compareTo(b.totalAmount ?? 0));
    }
    return copy;
  }

  Future<void> _confirmDelete(BuildContext context, Receipt receipt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete receipt?'),
        content: Text(
          'This will permanently remove the receipt from '
          '${receipt.storeName?.isNotEmpty == true ? receipt.storeName! : 'Unknown store'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && receipt.id != null) {
      await ref.read(receiptsProvider.notifier).deleteReceipt(receipt.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final receiptsAsync = ref.watch(receiptsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt History'),
        actions: [
          PopupMenuButton<_ReceiptSort>(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort),
            initialValue: _sort,
            onSelected: (value) => setState(() => _sort = value),
            itemBuilder: (_) => _ReceiptSort.values
                .map((s) => PopupMenuItem(
                      value: s,
                      child: Row(
                        children: [
                          if (_sort == s) ...[
                            const Icon(Icons.check, size: 16),
                            const SizedBox(width: 8),
                          ] else
                            const SizedBox(width: 24),
                          Text(s.label),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      floatingActionButton: kIsWeb
          ? null
          : FloatingActionButton(
              tooltip: 'Scan receipt',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanScreen()),
              ),
              child: const Icon(Icons.document_scanner),
            ),
      body: receiptsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) {
          final code = _extractCode(e.toString());
          return ErrorBanner(
            message: toUserMessage(code),
            onRetry: () => ref.invalidate(receiptsProvider),
          );
        },
        data: (receipts) {
          if (receipts.isEmpty) {
            return const _EmptyState();
          }
          final sorted = _sorted(receipts);
          return RefreshIndicator(
            onRefresh: () => ref.read(receiptsProvider.notifier).refresh(),
            child: ListView.builder(
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final receipt = sorted[index];
                return Dismissible(
                  key: ValueKey(receipt.id ?? index),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    await _confirmDelete(context, receipt);
                    // Always return false — deleteReceipt updates state itself.
                    return false;
                  },
                  child: ReceiptListItem(receipt: receipt),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String? _extractCode(String errorMessage) {
    final match = RegExp(r'^\[(.+?)\]').firstMatch(errorMessage);
    return match?.group(1);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Scan your first receipt',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the + button to get started.',
            style: TextStyle(color: Colors.grey),
          ),
          if (kIsWeb) ...[
            SizedBox(height: 8),
            Text(
              'Receipt scanning is available on the mobile app.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
