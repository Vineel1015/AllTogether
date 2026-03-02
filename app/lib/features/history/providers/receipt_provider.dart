import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/app_result.dart';
import '../../../services/food_facts_service.dart';
import '../models/food_item_model.dart';
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

  /// Optimistically removes [id] from the list, then deletes from Supabase.
  /// Restores the previous list if the delete fails.
  Future<void> deleteReceipt(String id) async {
    final previous = state.valueOrNull ?? [];
    state = AsyncData(previous.where((r) => r.id != id).toList());

    final result =
        await ref.read(receiptServiceProvider).deleteReceipt(id);
    if (result is AppFailure) {
      state = AsyncData(previous);
    }
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

// ── Food item lookup ─────────────────────────────────────────────────────────

/// Looks up a [FoodItem] by normalized name, using the 30-day Hive cache.
/// Returns null when no product is found or on error.
final foodItemByNameProvider =
    FutureProvider.family<FoodItem?, String>((ref, name) async {
  final result =
      await ref.read(foodFactsServiceProvider).lookupItem(name);
  return result is AppSuccess<FoodItem?> ? result.data : null;
});
