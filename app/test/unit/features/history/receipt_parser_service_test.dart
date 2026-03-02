import 'package:flutter_test/flutter_test.dart';

import 'package:all_together/features/history/services/receipt_parser_service.dart';

void main() {
  late ReceiptParserService parser;

  setUp(() => parser = ReceiptParserService());

  group('ReceiptParserService.parseItems', () {
    test('parses a well-formed receipt into correct items', () {
      const raw = '''
WHOLE MILK 1GAL   4.99
CHICKEN BREAST    6.49
ORGANIC SPINACH   2.99
SUBTOTAL          14.47
TAX               1.16
TOTAL             15.63
THANK YOU
''';

      final items = parser.parseItems(raw);

      expect(items.length, 3);
      expect(items[0].rawName, 'WHOLE MILK 1GAL');
      expect(items[0].price, closeTo(4.99, 0.001));
      expect(items[1].rawName, 'CHICKEN BREAST');
      expect(items[1].price, closeTo(6.49, 0.001));
      expect(items[2].rawName, 'ORGANIC SPINACH');
      expect(items[2].price, closeTo(2.99, 0.001));
    });

    test('skips TOTAL, TAX, SUBTOTAL, and THANK YOU lines', () {
      const raw = '''
APPLE JUICE       2.50
TOTAL             2.50
TAX               0.20
SUBTOTAL          2.50
THANK YOU
''';
      final items = parser.parseItems(raw);
      expect(items.length, 1);
      expect(items.first.rawName, 'APPLE JUICE');
    });

    test('normalizes item names via normalizeItemName', () {
      const raw = 'WHL MLK   3.99\n';
      final items = parser.parseItems(raw);

      expect(items.length, 1);
      // 'WHL MLK' normalizes to 'whole milk' after abbreviation expansion
      expect(items.first.normalizedName, contains('whole'));
      expect(items.first.normalizedName, contains('milk'));
    });

    test('returns empty list for unrecognizable text', () {
      const raw = '''
THANK YOU FOR SHOPPING
HAVE A GREAT DAY
''';
      final items = parser.parseItems(raw);
      expect(items, isEmpty);
    });

    test('handles lines without dollar sign prefix', () {
      const raw = 'BREAD   1.29\n';
      final items = parser.parseItems(raw);
      expect(items.length, 1);
      expect(items.first.price, closeTo(1.29, 0.001));
    });

    test('handles lines with dollar sign prefix', () {
      const raw = r'BUTTER   $4.19' '\n';
      final items = parser.parseItems(raw);
      expect(items.length, 1);
      expect(items.first.price, closeTo(4.19, 0.001));
    });

    test('returns empty list for completely empty input', () {
      expect(parser.parseItems(''), isEmpty);
    });
  });
}
