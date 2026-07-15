import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reception_provider.dart';

class FreezeSubscriptionDialog extends StatefulWidget {
  const FreezeSubscriptionDialog({super.key});

  @override
  State<FreezeSubscriptionDialog> createState() => _FreezeSubscriptionDialogState();
}

class _FreezeSubscriptionDialogState extends State<FreezeSubscriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subscriptionIdController = TextEditingController();
  final _freezeDaysController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _subscriptionIdController.dispose();
    _freezeDaysController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<ReceptionProvider>();
    final result = await provider.freezeSubscription(
      subscriptionId: int.parse(_subscriptionIdController.text),
      freezeDays: int.parse(_freezeDaysController.text),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success'] == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Subscription frozen successfully'),
            backgroundColor: Colors.green,
          ),
        );
        provider.refresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to freeze subscription'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.pause_circle, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Freeze Subscription',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Temporarily pause a subscription without losing remaining days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Color(0xFF6B7590),
                      ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _subscriptionIdController,
                  decoration: const InputDecoration(
                    labelText: 'Subscription ID *',
                    prefixIcon: Icon(Icons.card_membership),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _freezeDaysController,
                  decoration: const InputDecoration(
                    labelText: 'Freeze Days *',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                    helperText: 'Number of days to freeze',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Required';
                    final days = int.tryParse(v!);
                    if (days == null || days < 1) return 'Must be at least 1 day';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleSubmit,
                      icon: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.pause),
                      label: const Text('Freeze'),
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
