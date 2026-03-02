/// A single line item parsed from a scanned receipt.
///
/// Stored in the `receipt_items` Supabase table.
class ReceiptItem {
  final String? id;
  final String receiptId;

  /// Normalized OCR text (lowercased, abbreviations expanded).
  final String name;

  /// Original OCR text before normalization.
  final String rawName;

  final double quantity;
  final double? price;

  /// Open Food Facts product ID if a nutrition match was found.
  final String? matchedFoodId;

  const ReceiptItem({
    this.id,
    required this.receiptId,
    required this.name,
    required this.rawName,
    this.quantity = 1.0,
    this.price,
    this.matchedFoodId,
  });

  // ── Factories ─────────────────────────────────────────────────────────────

  factory ReceiptItem.fromSupabaseJson(Map<String, dynamic> json) =>
      ReceiptItem(
        id: json['id'] as String?,
        receiptId: json['receipt_id'] as String,
        name: json['name'] as String? ?? '',
        rawName: json['raw_name'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
        price: (json['price'] as num?)?.toDouble(),
        matchedFoodId: json['matched_food_id'] as String?,
      );

  factory ReceiptItem.fromJson(Map<String, dynamic> json) =>
      ReceiptItem.fromSupabaseJson(json);

  // ── Serializers ───────────────────────────────────────────────────────────

  Map<String, dynamic> toSupabaseJson() => {
        if (id != null) 'id': id,
        'receipt_id': receiptId,
        'name': name,
        'raw_name': rawName,
        'quantity': quantity,
        if (price != null) 'price': price,
        if (matchedFoodId != null) 'matched_food_id': matchedFoodId,
      };

  Map<String, dynamic> toJson() => toSupabaseJson();
}
