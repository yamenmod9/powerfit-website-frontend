import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_strings.dart';
import '../providers/reception_provider.dart';
import 'customer_subscription_field.dart';

class FreezeSubscriptionDialog extends StatefulWidget {
  const FreezeSubscriptionDialog({super.key});

  @override
  State<FreezeSubscriptionDialog> createState() => _FreezeSubscriptionDialogState();
}

class _FreezeSubscriptionDialogState extends State<FreezeSubscriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _freezeDaysController = TextEditingController();
  int? _subscriptionId;
  bool _isLoading = false;

  @override
  void dispose() {
    _freezeDaysController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_subscriptionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.pleaseSelectSubscription)),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<ReceptionProvider>();
    final result = await provider.freezeSubscription(
      subscriptionId: _subscriptionId!,
      freezeDays: int.parse(_freezeDaysController.text),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success'] == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? S.subscriptionFrozen),
            backgroundColor: Colors.green,
          ),
        );
        provider.refresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? S.failedToFreeze),
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
                        S.freezeSubscription,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    S.freezeDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7590),
                        ),
                  ),
                  const SizedBox(height: 24),

                  CustomerSubscriptionField(
                    allowedStatuses: const {'active'},
                    onSubscriptionSelected: (id) => _subscriptionId = id,
                  ),
                  const SizedBox(height: 4),

                  TextFormField(
                    controller: _freezeDaysController,
                    decoration: InputDecoration(
                      labelText: S.freezeDaysRequired,
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: const OutlineInputBorder(),
                      helperText: S.numberOfDaysToFreeze,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v?.isEmpty ?? true) return S.required;
                      final days = int.tryParse(v!);
                      if (days == null || days < 1) return S.atLeast1Day;
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        child: Text(S.cancel),
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
                        label: Text(S.freeze),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
