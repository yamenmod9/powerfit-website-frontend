import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../core/localization/app_strings.dart';
import 'receipt_pdf.dart';

/// Print or share the receipt for a transaction.
///
/// One entry point for both actions so every caller (accountant ledger, money
/// page, reception) offers the same sheet. Printing goes to the platform print
/// dialog; sharing opens the OS share sheet on mobile and downloads the PDF on
/// web — `printing` handles that per-platform, so callers don't branch.
class ReceiptActions {
  const ReceiptActions._();

  /// Show a bottom sheet offering Print and Share for [transaction].
  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> transaction,
    required String gymName,
  }) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.print),
              title: Text(S.print),
              onTap: () => Navigator.pop(context, 'print'),
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(S.share),
              onTap: () => Navigator.pop(context, 'share'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (action == null) return;
    if (action == 'print') {
      await print(transaction: transaction, gymName: gymName);
    } else {
      await share(transaction: transaction, gymName: gymName);
    }
  }

  /// Send the receipt straight to the print dialog.
  static Future<void> print({
    required Map<String, dynamic> transaction,
    required String gymName,
  }) async {
    final bytes = await ReceiptPdf.build(transaction: transaction, gymName: gymName);
    await Printing.layoutPdf(
      onLayout: (_) => bytes,
      name: ReceiptPdf.receiptNumber(transaction),
    );
  }

  /// Open the share sheet (mobile) or download the PDF (web).
  static Future<void> share({
    required Map<String, dynamic> transaction,
    required String gymName,
  }) async {
    final bytes = await ReceiptPdf.build(transaction: transaction, gymName: gymName);
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${ReceiptPdf.receiptNumber(transaction)}.pdf',
    );
  }
}
