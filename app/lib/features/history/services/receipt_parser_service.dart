import '../../../core/utils/string_utils.dart';

/// A parsed line item extracted from raw OCR receipt text.
typedef ParsedItem = ({
  String rawName,
  String normalizedName,
  double? price,
});

/// Parses raw OCR receipt text into structured line items.
///
/// This is a pure, stateless service — no network calls, no Hive access.
class ReceiptParserService {
  // Matches lines of the form:
  //   "WHOLE MILK 1GAL   4.99"
  //   "CHICKEN BREAST   $3.49"
  static final _lineRegex = RegExp(r'^(.+?)\s+\$?(\d+\.\d{2})\s*$');

  // Lines matching these patterns are footer/summary rows and should be skipped.
  static final _skipRegex = RegExp(
    r'\b(subtotal|total|tax|thank\s+you)\b',
    caseSensitive: false,
  );

  /// Parses [rawText] into a list of line items.
  ///
  /// Returns an empty list (not a failure) when no items could be matched.
  List<ParsedItem> parseItems(String rawText) {
    final results = <ParsedItem>[];

    for (final line in rawText.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (_skipRegex.hasMatch(trimmed)) continue;

      final match = _lineRegex.firstMatch(trimmed);
      if (match == null) continue;

      final rawName = match.group(1)!.trim();
      final price = double.tryParse(match.group(2)!);

      results.add((
        rawName: rawName,
        normalizedName: normalizeItemName(rawName),
        price: price,
      ));
    }

    return results;
  }
}
