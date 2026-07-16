import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/localization/app_strings.dart';
import '../../../core/utils/helpers.dart';

/// Renders a printable proof of payment for a single transaction.
///
/// This is a *receipt*, not a tax invoice. Nothing in the schema carries a VAT
/// rate, a VAT amount, or a registration number, and there is no company legal
/// entity — only branches. So the document says "Payment receipt" and claims no
/// tax status. Making it a compliant tax invoice is a data-model change, not a
/// rendering change.
class ReceiptPdf {
  const ReceiptPdf._();

  /// Receipt numbers are **derived, never stored**.
  ///
  /// `Transaction.id` is an autoincrement primary key on an append-only table
  /// (the API exposes no update or delete), so the same transaction always
  /// renders the same number, and a reprint is byte-identical to the original —
  /// without a counter, a table, or any migration to keep in sync.
  ///
  /// The sequence is global, so a single branch sees gaps where other branches'
  /// transactions fall between its own. Gapless per-branch numbering is the one
  /// thing this cannot do; that needs a stored series.
  static String receiptNumber(Map<String, dynamic> transaction) {
    final id = ((transaction['id'] ?? 0) as num).toInt();
    final issuedAt = _dateOf(transaction) ?? DateTime.now();
    return 'RCP-${issuedAt.year}-${id.toString().padLeft(6, '0')}';
  }

  static DateTime? _dateOf(Map<String, dynamic> transaction) =>
      DateTime.tryParse(
        (transaction['transaction_date'] ?? transaction['created_at'] ?? '')
            .toString(),
      );

  static double _num(dynamic value) => ((value ?? 0) as num).toDouble();

  static String? _text(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  /// What was actually paid for. The service name is the most specific thing
  /// available; the free-text description and the transaction type are fallbacks.
  static String _lineItem(Map<String, dynamic> transaction) =>
      _text(transaction['service_name']) ??
      _text(transaction['description']) ??
      S.transactionTypeLabel((transaction['transaction_type'] ?? '').toString());

  /// Builds the PDF bytes for [transaction], as returned by
  /// /api/transactions/{id}.
  ///
  /// [gymName] comes from the caller because the gym's identity lives only in
  /// client-side branding storage — the backend has no company record.
  static Future<Uint8List> build({
    required Map<String, dynamic> transaction,
    required String gymName,
  }) async {
    // Deliberately NOT the app's Cairo face.
    //
    // A PDF viewer draws glyph ids and never applies GSUB, so the writer has to
    // pre-shape Arabic itself — the `pdf` package does that by mapping to the
    // legacy Arabic Presentation Forms-B block (U+FE70-FEFF) and looking those
    // up in the font's cmap. Cairo shapes via GSUB like any modern face and
    // carries only 89 of those 141 forms; the isolated dal, reh and yeh are all
    // absent, so "نادي" and "شهري" render as garbage while "التنين" looks fine.
    // Noto Sans Arabic ships all 141 and is a sans in the same spirit as Cairo.
    final arabic = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'),
    );

    final document = pw.Document(
      // One weight ships, so bold reuses it rather than falling back to a face
      // with no Arabic coverage at all.
      theme: pw.ThemeData.withFont(base: arabic, bold: arabic),
    );

    final gross = _num(transaction['amount']);
    final discount = _num(transaction['discount']);
    final net = gross - discount;
    final issuedAt = _dateOf(transaction);

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) => pw.Directionality(
          textDirection: S.isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _header(transaction, gymName),
              pw.SizedBox(height: 14),
              pw.Divider(color: PdfColors.grey400, height: 1),
              pw.SizedBox(height: 14),
              _titleRow(transaction, issuedAt),
              pw.SizedBox(height: 16),
              _details(transaction),
              pw.SizedBox(height: 16),
              _lineItems(transaction, gross, discount, net),
              pw.Spacer(),
              _footer(transaction),
            ],
          ),
        ),
      ),
    );

    return document.save();
  }

  static pw.Widget _header(Map<String, dynamic> transaction, String gymName) {
    final branchLine = [
      _text(transaction['branch_name']),
      _text(transaction['branch_city']),
    ].whereType<String>().join(' · ');

    final contactLine = [
      _text(transaction['branch_address']),
      _text(transaction['branch_phone']),
    ].whereType<String>().join(' · ');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          gymName,
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        if (branchLine.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(branchLine,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        ],
        if (contactLine.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(contactLine,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ],
      ],
    );
  }

  static pw.Widget _titleRow(Map<String, dynamic> transaction, DateTime? issuedAt) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          S.paymentReceipt,
          style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              receiptNumber(transaction),
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            if (issuedAt != null) ...[
              pw.SizedBox(height: 2),
              pw.Text(
                DateHelper.formatDateTime(issuedAt),
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
          ],
        ),
      ],
    );
  }

  static pw.Widget _details(Map<String, dynamic> transaction) {
    final rows = <(String, String)>[
      if (_text(transaction['customer_name']) != null)
        (S.member, transaction['customer_name'].toString()),
      (
        S.paymentMethod,
        S.paymentMethodLabel((transaction['payment_method'] ?? '').toString())
      ),
      // Only card and transfer payments carry one, so cash receipts skip it
      // rather than printing an empty field.
      if (_text(transaction['reference_number']) != null)
        (S.referenceNumberLabel, transaction['reference_number'].toString()),
    ];

    return pw.Column(
      children: [
        for (final row in rows)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 90,
                  child: pw.Text(
                    row.$1,
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(row.$2, style: const pw.TextStyle(fontSize: 10)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static pw.Widget _lineItems(
    Map<String, dynamic> transaction,
    double gross,
    double discount,
    double net,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  S.item,
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ),
              pw.Text(
                S.amount,
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(_lineItem(transaction),
                    style: const pw.TextStyle(fontSize: 11)),
              ),
              pw.Text(NumberHelper.formatCurrency(gross),
                  style: const pw.TextStyle(fontSize: 11)),
            ],
          ),
          // A zero discount is noise on a receipt; only show it when it moved
          // the total.
          if (discount > 0) ...[
            pw.SizedBox(height: 6),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text(S.discount,
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                ),
                pw.Text('- ${NumberHelper.formatCurrency(discount)}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
          ],
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.grey400, height: 1),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  S.total,
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Text(
                NumberHelper.formatCurrency(net),
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _footer(Map<String, dynamic> transaction) {
    final issuedBy = _text(transaction['created_by_name']);
    if (issuedBy == null) return pw.SizedBox();
    return pw.Text(
      '${S.issuedBy}: $issuedBy',
      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
    );
  }
}
