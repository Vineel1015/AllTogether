import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_result.dart';
import '../models/receipt_model.dart';
import 'receipt_provider.dart';

/// Manages the receipt scanning operation state.
///
/// Idle state is `null`. After a successful scan the state holds the new
/// [Receipt] and the [receiptsProvider] is invalidated so the list refreshes.
final scanNotifierProvider =
    AsyncNotifierProvider<ScanNotifier, Receipt?>(ScanNotifier.new);

class ScanNotifier extends AsyncNotifier<Receipt?> {
  @override
  Future<Receipt?> build() async => null; // idle

  /// Scans the receipt image at [imagePath] and persists the result.
  Future<void> scan(String imagePath) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result =
          await ref.read(receiptServiceProvider).scanReceipt(imagePath);

      return switch (result) {
        AppSuccess(:final data) => data,
        AppFailure(:final message, :final code) =>
          throw Exception('[$code] $message'),
      };
    });

    // Invalidate the list so HistoryScreen auto-refreshes
    if (state is AsyncData<Receipt?>) {
      ref.invalidate(receiptsProvider);
    }
  }
}
