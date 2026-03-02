import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/app_result.dart';
import '../../../services/food_facts_service.dart';
import '../models/receipt_model.dart';
import '../services/ocr_service.dart';
import '../services/receipt_parser_service.dart';
import '../services/receipt_service.dart';

// ── Service providers ────────────────────────────────────────────────────────

final foodFactsServiceProvider = Provider<FoodFactsService>(
  (_) => FoodFactsService(),
);

final receiptServiceProvider = Provider<ReceiptService>((ref) {
  return ReceiptService(
    ocr: OcrService(),
    parser: ReceiptParserService(),
    foodFacts: ref.read(foodFactsServiceProvider),
    supabase: Supabase.instance.client,
  );
});

// ── Receipts list notifier ───────────────────────────────────────────────────

final receiptsProvider =
    AsyncNotifierProvider<ReceiptsNotifier, List<Receipt>>(
  ReceiptsNotifier.new,
);

class ReceiptsNotifier extends AsyncNotifier<List<Receipt>> {
  @override
  Future<List<Receipt>> build() => _fetch();

  /// Re-fetches the receipt list from Supabase.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<List<Receipt>> _fetch() async {
    final result =
        await ref.read(receiptServiceProvider).getReceipts();

    return switch (result) {
      AppSuccess(:final data) => data,
      AppFailure(:final message, :final code) =>
        throw Exception('[$code] $message'),
    };
  }
}
