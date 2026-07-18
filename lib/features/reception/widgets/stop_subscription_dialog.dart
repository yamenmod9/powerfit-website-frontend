import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_strings.dart';
import '../providers/reception_provider.dart';
import 'customer_subscription_field.dart';

class StopSubscriptionDialog extends StatefulWidget {
  const StopSubscriptionDialog({super.key});

  @override
  State<StopSubscriptionDialog> createState() => _StopSubscriptionDialogState();
}

class _StopSubscriptionDialogState extends State<StopSubscriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _subscriptionId;
  bool _isLoading = false;

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_subscriptionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.pleaseSelectSubscription)),
      );
      return;
    }

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.confirmStop),
        content: Text(S.stopConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(S.stop),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    final provider = context.read<ReceptionProvider>();
    final result = await provider.stopSubscription(_subscriptionId!);

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success'] == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? S.subscriptionStopped),
            backgroundColor: Colors.green,
          ),
        );
        provider.refresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? S.failedToStop),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stop, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        S.stopSubscription,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          S.stopWillDeactivate,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.red[700],
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                CustomerSubscriptionField(
                  allowedStatuses: const {'active', 'frozen'},
                  onSubscriptionSelected: (id) => _subscriptionId = id,
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: Text(S.cancel),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.stop, size: 18),
                      label: Text(S.stop),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
