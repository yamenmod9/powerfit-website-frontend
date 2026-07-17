import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/record_payment_dialog.dart';
import '../widgets/submit_complaint_dialog.dart';
import '../providers/reception_provider.dart';
import '../../../core/localization/app_strings.dart';

class OperationsScreen extends StatelessWidget {
  const OperationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.dailyOperations),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), // Extra bottom padding for navbar
        children: [
          // Daily Closing — the day's headline action, kept visually distinct
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              onTap: () => _performDailyClosing(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle, color: Colors.purple, size: 22),
              ),
              title: Text(S.dailyClosing,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                S.finalizeTodayTransactions,
                style: const TextStyle(fontSize: 12, color: Color(0xFF9AA3B8)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFF9AA3B8)),
            ),
          ),

          // Operations
          _buildOperationRow(
            context,
            title: S.recordPayment,
            icon: Icons.payment,
            color: Colors.orange,
            onTap: () => _showRecordPaymentDialog(context),
          ),
          _buildOperationRow(
            context,
            title: S.submitComplaint,
            icon: Icons.report_problem,
            color: Colors.deepOrange,
            onTap: () => _showSubmitComplaintDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationRow(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF9AA3B8)),
      ),
    );
  }

  void _showRecordPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const RecordPaymentDialog(),
    );
  }

  void _showSubmitComplaintDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SubmitComplaintDialog(),
    );
  }

  Future<void> _performDailyClosing(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.dailyClosing),
        content: Text(
          S.dailyClosingConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final provider = context.read<ReceptionProvider>();
      final result = await provider.dailyClosing();

      if (context.mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? S.dailyClosingCompleted),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? S.dailyClosingFailed),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

