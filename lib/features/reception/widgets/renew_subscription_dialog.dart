import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_strings.dart';
import '../providers/reception_provider.dart';
import 'customer_subscription_field.dart';

class RenewSubscriptionDialog extends StatefulWidget {
  const RenewSubscriptionDialog({super.key});

  @override
  State<RenewSubscriptionDialog> createState() => _RenewSubscriptionDialogState();
}

class _RenewSubscriptionDialogState extends State<RenewSubscriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  int? _subscriptionId;
  String _paymentMethod = 'cash';
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
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
    final result = await provider.renewSubscription(
      subscriptionId: _subscriptionId!,
      amount: double.parse(_amountController.text),
      paymentMethod: _paymentMethod,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success'] == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? S.subscriptionRenewed),
            backgroundColor: Colors.green,
          ),
        );
        provider.refresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? S.failedToRenew),
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
                      Icon(Icons.refresh, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        S.renewSubscription,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  CustomerSubscriptionField(
                    onSubscriptionSelected: (id) => _subscriptionId = id,
                  ),
                  const SizedBox(height: 4),

                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: S.amountRequired,
                      prefixIcon: const Icon(Icons.attach_money),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v?.isEmpty ?? true) return S.required;
                      if (double.tryParse(v!) == null) return S.invalidAmount;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: InputDecoration(
                      labelText: S.paymentMethodRequired,
                      prefixIcon: const Icon(Icons.payment),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'cash', child: Text(S.cash)),
                      DropdownMenuItem(value: 'card', child: Text(S.card)),
                      DropdownMenuItem(value: 'transfer', child: Text(S.transfer)),
                    ],
                    onChanged: (v) => setState(() => _paymentMethod = v!),
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
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(S.renew),
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
