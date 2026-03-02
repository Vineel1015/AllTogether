import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/app_result.dart';
import '../../../services/food_facts_service.dart';
import '../models/receipt_item_model.dart';
import '../models/receipt_model.dart';
import 'ocr_service.dart';
import 'receipt_parser_service.dart';

/// Orchestrates the full receipt scanning pipeline:
///
///   Image → OcrService → ReceiptParserService → FoodFactsService
///       → Supabase (receipts + receipt_items) → Receipt
class ReceiptService {
  final OcrService _ocr;
  final ReceiptParserService _parser;
  final FoodFactsService _foodFacts;
  final SupabaseClient _supabase;

  ReceiptService({
    required OcrService ocr,
    required ReceiptParserService parser,
    required FoodFactsService foodFacts,
    required SupabaseClient supabase,
  })  : _ocr = ocr,
        _parser = parser,
        _foodFacts = foodFacts,
        _supabase = supabase;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Full pipeline: OCR → parse → nutrition lookup → persist → return [Receipt].
  Future<AppResult<Receipt>> scanReceipt(String imagePath) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return const AppFailure(
        'Session expired. Please sign in again.',
        code: '401',
      );
    }

    // 1. OCR
    final ocrResult = await _ocr.extractText(imagePath);
    if (ocrResult is AppFailure<String>) {
      return AppFailure(
        ocrResult.message,
        code: ocrResult.code,
        isRetryable: ocrResult.isRetryable,
      );
    }
    final rawText = (ocrResult as AppSuccess<String>).data;

    // 2. Parse line items
    final parsedItems = _parser.parseItems(rawText);

    // 3. Nutrition lookup for each item (errors are non-fatal — store without data)
    final itemBuilders = <_ItemBuilder>[];
    for (final parsed in parsedItems) {
      String? matchedFoodId;
      try {
        final foodResult =
            await _foodFacts.lookupItem(parsed.normalizedName);
        if (foodResult is AppSuccess) {
          matchedFoodId = (foodResult as AppSuccess).data?.id;
        }
      } catch (e) {
        debugPrint('[ReceiptService] nutrition lookup failed: $e');
      }
      itemBuilders.add(_ItemBuilder(
        rawName: parsed.rawName,
        normalizedName: parsed.normalizedName,
        price: parsed.price,
        matchedFoodId: matchedFoodId,
      ));
    }

    // 4. Compute total from parsed items
    final total = parsedItems.fold<double>(
      0.0,
      (sum, item) => sum + (item.price ?? 0.0),
    );

    // 5. Insert receipt row into Supabase
    final receiptPayload = Receipt(
      userId: userId,
      scannedAt: DateTime.now(),
      rawOcrText: rawText,
      totalAmount: total > 0 ? total : null,
    );

    try {
      final insertedRows = await _supabase
          .from('receipts')
          .insert(receiptPayload.toSupabaseJson())
          .select()
          .single();

      final receipt = Receipt.fromSupabaseJson(insertedRows);

      // 6. Batch-insert receipt_items
      if (itemBuilders.isNotEmpty) {
        final itemsPayload = itemBuilders
            .map((b) => ReceiptItem(
                  receiptId: receipt.id!,
                  name: b.normalizedName,
                  rawName: b.rawName,
                  price: b.price,
                  matchedFoodId: b.matchedFoodId,
                ).toSupabaseJson())
            .toList();

        final insertedItems = await _supabase
            .from('receipt_items')
            .insert(itemsPayload)
            .select();

        final items = (insertedItems as List)
            .map((r) =>
                ReceiptItem.fromSupabaseJson(r as Map<String, dynamic>))
            .toList();

        return AppSuccess(receipt.copyWith(items: items));
      }

      return AppSuccess(receipt.copyWith(items: []));
    } on PostgrestException catch (e) {
      return AppFailure(
        e.message,
        code: e.code,
        isRetryable: true,
      );
    } catch (e) {
      return AppFailure('Failed to save receipt: $e');
    }
  }

  /// Fetches all receipts for the current user, ordered newest-first.
  Future<AppResult<List<Receipt>>> getReceipts() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return const AppFailure(
        'Session expired. Please sign in again.',
        code: '401',
      );
    }

    try {
      final rows = await _supabase
          .from('receipts')
          .select('*, receipt_items(*)')
          .eq('user_id', userId)
          .order('scanned_at', ascending: false);

      final receipts = (rows as List)
          .map((r) => Receipt.fromSupabaseJson(r as Map<String, dynamic>))
          .toList();

      return AppSuccess(receipts);
    } on PostgrestException catch (e) {
      return AppFailure(
        e.message,
        code: e.code,
        isRetryable: true,
      );
    } catch (e) {
      return AppFailure('Failed to load receipts: $e');
    }
  }
}

/// Internal helper to carry parsed item data before a receipt ID is available.
class _ItemBuilder {
  final String rawName;
  final String normalizedName;
  final double? price;
  final String? matchedFoodId;

  const _ItemBuilder({
    required this.rawName,
    required this.normalizedName,
    this.price,
    this.matchedFoodId,
  });
}
