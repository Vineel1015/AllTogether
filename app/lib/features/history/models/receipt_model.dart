import 'receipt_item_model.dart';

/// A scanned receipt stored in the `receipts` Supabase table.
class Receipt {
  final String? id;
  final String userId;
  final DateTime scannedAt;
  final String? storeName;
  final String rawOcrText;
  final double? totalAmount;
  final String? imageUrl;

  /// Items are populated after batch-inserting to Supabase; nullable for
  /// partial construction during the pipeline.
  final List<ReceiptItem> items;

  const Receipt({
    this.id,
    required this.userId,
    required this.scannedAt,
    this.storeName,
    required this.rawOcrText,
    this.totalAmount,
    this.imageUrl,
    this.items = const [],
  });

  // ── Factories ─────────────────────────────────────────────────────────────

  factory Receipt.fromSupabaseJson(Map<String, dynamic> json) => Receipt(
        id: json['id'] as String?,
        userId: json['user_id'] as String,
        scannedAt: json['scanned_at'] != null
            ? DateTime.parse(json['scanned_at'] as String)
            : DateTime.now(),
        storeName: json['store_name'] as String?,
        rawOcrText: json['raw_ocr_text'] as String? ?? '',
        totalAmount: (json['total_amount'] as num?)?.toDouble(),
        imageUrl: json['image_url'] as String?,
        items: (json['receipt_items'] as List? ?? [])
            .map((i) => ReceiptItem.fromSupabaseJson(i as Map<String, dynamic>))
            .toList(),
      );

  factory Receipt.fromJson(Map<String, dynamic> json) =>
      Receipt.fromSupabaseJson(json);

  // ── Serializers ───────────────────────────────────────────────────────────

  Map<String, dynamic> toSupabaseJson() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'scanned_at': scannedAt.toIso8601String(),
        if (storeName != null) 'store_name': storeName,
        'raw_ocr_text': rawOcrText,
        if (totalAmount != null) 'total_amount': totalAmount,
        if (imageUrl != null) 'image_url': imageUrl,
      };

  Map<String, dynamic> toJson() => toSupabaseJson();

  // ── copyWith ──────────────────────────────────────────────────────────────

  Receipt copyWith({
    String? id,
    List<ReceiptItem>? items,
  }) =>
      Receipt(
        id: id ?? this.id,
        userId: userId,
        scannedAt: scannedAt,
        storeName: storeName,
        rawOcrText: rawOcrText,
        totalAmount: totalAmount,
        imageUrl: imageUrl,
        items: items ?? this.items,
      );
}
