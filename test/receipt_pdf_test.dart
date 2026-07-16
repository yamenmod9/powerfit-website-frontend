import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_frontend/core/localization/app_strings.dart';
import 'package:gym_frontend/core/utils/helpers.dart';
import 'package:gym_frontend/features/finance/services/receipt_pdf.dart';
import 'package:pdf/pdf.dart' show TtfParser;

Map<String, dynamic> _transaction({
  int id = 123,
  String? date = '2026-02-14T10:30:00',
  double amount = 500,
  double discount = 0,
  String method = 'cash',
  String? reference,
  String? customer = 'Ahmed Hassan',
  String? service = 'Monthly Gym',
}) =>
    {
      'id': id,
      'amount': amount,
      'discount': discount,
      'payment_method': method,
      'transaction_type': 'subscription',
      'branch_name': 'Dragon Club',
      'branch_address': '12 Nile St.',
      'branch_phone': '0201234567',
      'branch_city': 'Cairo',
      'customer_name': customer,
      'service_name': service,
      'created_by_name': 'Reception One',
      'reference_number': reference,
      'transaction_date': date,
      'created_at': date,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => S.setArabic(false));
  tearDown(() => S.setArabic(true));

  group('receiptNumber', () {
    test('derives from the transaction id and year, zero-padded', () {
      expect(ReceiptPdf.receiptNumber(_transaction()), 'RCP-2026-000123');
    });

    test('is stable across calls — a reprint is identical', () {
      final txn = _transaction();
      expect(ReceiptPdf.receiptNumber(txn), ReceiptPdf.receiptNumber(txn));
    });

    test('pads short ids without truncating long ones', () {
      expect(ReceiptPdf.receiptNumber(_transaction(id: 1)), 'RCP-2026-000001');
      expect(
        ReceiptPdf.receiptNumber(_transaction(id: 1234567)),
        'RCP-2026-1234567',
      );
    });

    test('takes the year from the transaction date, not today', () {
      expect(
        ReceiptPdf.receiptNumber(_transaction(date: '2019-07-01T00:00:00')),
        'RCP-2019-000123',
      );
    });

    test('falls back to created_at, then now, when the date is unusable', () {
      final noDate = _transaction(date: null)..remove('created_at');
      expect(
        ReceiptPdf.receiptNumber(noDate),
        'RCP-${DateTime.now().year}-000123',
      );
    });
  });

  group('build', () {
    test('produces a valid PDF', () async {
      final bytes = await ReceiptPdf.build(
        transaction: _transaction(),
        gymName: 'PowerFit',
      );

      expect(bytes.length, greaterThan(1000));
      // A PDF always opens with the %PDF- magic bytes.
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('renders in Arabic without throwing on RTL or missing glyphs',
        () async {
      S.setArabic(true);
      final bytes = await ReceiptPdf.build(
        transaction: _transaction(customer: 'أحمد حسن', service: 'اشتراك شهري'),
        gymName: 'نادي التنين',
      );

      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('renders a cash sale with no member and no reference number',
        () async {
      // Walk-in cash: customer_name and reference_number are both null, and
      // neither field should be printed as an empty row.
      final bytes = await ReceiptPdf.build(
        transaction: _transaction(customer: null, service: null),
        gymName: 'PowerFit',
      );

      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('renders a discounted card payment with a reference', () async {
      final bytes = await ReceiptPdf.build(
        transaction: _transaction(
          amount: 500,
          discount: 50,
          method: 'network',
          reference: 'REF-99',
        ),
        gymName: 'PowerFit',
      );

      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });

  group('receipt font', () {
    // The bug these pin was invisible to every other test in this file: the PDF
    // built, started with %PDF-, and threw nothing — it just silently dropped
    // letters. Only rasterising the page and looking at it caught that
    // "نادي التنين" had printed as "ناد التنين".
    //
    // A PDF viewer draws glyph ids and never applies GSUB, so the `pdf` package
    // pre-shapes Arabic into the legacy Presentation Forms-B block and resolves
    // the result through the font's cmap. A modern face shapes via GSUB and has
    // no reason to carry that block: Cairo, the app's UI font, maps 124 of the
    // 141 assigned forms.
    //
    // The specific gap that bit is U+FEF1, yeh isolated. A final ي following a
    // non-connecting letter (د, ر) takes the isolated form rather than the
    // final one, so "نادي" and "شهري" lost their last letter, while "التنين"
    // and "النيل" — medial yeh — came out fine and made it look like a font
    // that mostly worked.
    const yehIsolated = 0xFEF1;

    test('maps yeh isolated, which Cairo lacks and the shaper needs', () async {
      final parser = TtfParser(
        await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'),
      );

      expect(
        parser.charToGlyphIndexMap[yehIsolated],
        isNotNull,
        reason: 'U+FEF1 (yeh isolated) is not in the receipt font. Words ending '
            'in دي/ري will silently lose their final letter. Do not point this '
            'at Cairo.',
      );
    });

    test('covers the whole presentation-forms block, not just that one probe',
        () async {
      final parser = TtfParser(
        await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'),
      );

      final mapped = [
        for (var cp = 0xFE70; cp <= 0xFEFF; cp++)
          if (parser.charToGlyphIndexMap[cp] != null) cp,
      ];
      // 141 of the block's slots are assigned characters. Cairo reaches 124,
      // so this is the assertion that would reject swapping the font back.
      expect(mapped.length, greaterThanOrEqualTo(141));
    });
  });

  group('currency', () {
    test('money is Egyptian pounds, not dollars', () {
      expect(NumberHelper.formatCurrency(1000), 'EGP 1,000.00');
      S.setArabic(true);
      expect(NumberHelper.formatCurrency(1000), 'ج.م 1,000.00');
    });
  });
}
