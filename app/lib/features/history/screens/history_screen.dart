import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/string_utils.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../providers/receipt_provider.dart';
import '../widgets/receipt_list_item.dart';
import 'scan_screen.dart';

/// History tab — lists all scanned receipts for the current user.
///
/// FAB opens [ScanScreen]. The [receiptsProvider] is invalidated by
/// [ScanNotifier] on success, so the list auto-refreshes.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(receiptsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Receipt History')),
      floatingActionButton: FloatingActionButton(
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
          return RefreshIndicator(
            onRefresh: () => ref.read(receiptsProvider.notifier).refresh(),
            child: ListView.builder(
              itemCount: receipts.length,
              itemBuilder: (context, index) =>
                  ReceiptListItem(receipt: receipts[index]),
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
        ],
      ),
    );
  }
}
