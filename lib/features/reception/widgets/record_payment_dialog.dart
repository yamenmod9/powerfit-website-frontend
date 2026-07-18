import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared/models/customer_model.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/reception_provider.dart';
import 'customer_search_field.dart';

class RecordPaymentDialog extends StatefulWidget {
  const RecordPaymentDialog({super.key});

  @override
  State<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  CustomerModel? _customer;
  String _paymentMethod = 'cash';
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_customer?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.pleaseSelectCustomer)),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<ReceptionProvider>();
    final result = await provider.recordPayment(
      customerId: _customer!.id!,
      amount: double.parse(_amountController.text),
      paymentMethod: _paymentMethod,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? S.paymentRecorded2),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? S.failedToRecord),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                children: [
                  const Icon(Icons.payment),
                  const SizedBox(width: 12),
                  Text(
                    S.recordPayment,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomerSearchField(
                        selected: _customer,
                        onSelected: (c) => setState(() => _customer = c),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: S.amountRequired,
                          prefixIcon: const Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => v?.isEmpty ?? true ? S.required : null,
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: _paymentMethod,
                        decoration: InputDecoration(
                          labelText: S.paymentMethodRequired,
                          prefixIcon: const Icon(Icons.payment),
                        ),
                        items: [
                          DropdownMenuItem(value: 'cash', child: Text(S.cash)),
                          DropdownMenuItem(value: 'card', child: Text(S.card)),
                          DropdownMenuItem(value: 'transfer', child: Text(S.transfer)),
                        ],
                        onChanged: (v) => setState(() => _paymentMethod = v!),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: S.notesOptional,
                          prefixIcon: const Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFF243050)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text(S.cancel),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading
                        ? const SmallLoadingIndicator()
                        : Text(S.record),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
