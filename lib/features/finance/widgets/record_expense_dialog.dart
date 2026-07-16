import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/finance_provider.dart';

/// Records money going out — maintenance, utilities, salaries and the rest.
///
/// [branches] are the branches the user may file against; when only one is
/// available it is preselected and the picker is hidden.
class RecordExpenseDialog extends StatefulWidget {
  final List<Map<String, dynamic>> branches;
  final int? defaultBranchId;
  final VoidCallback? onRecorded;

  const RecordExpenseDialog({
    super.key,
    this.branches = const [],
    this.defaultBranchId,
    this.onRecorded,
  });

  @override
  State<RecordExpenseDialog> createState() => _RecordExpenseDialogState();
}

class _RecordExpenseDialogState extends State<RecordExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = ExpenseCategories.maintenance;
  late DateTime _date = DateTime.now();
  int? _branchId;

  @override
  void initState() {
    super.initState();
    _branchId = widget.defaultBranchId ??
        (widget.branches.length == 1 ? _branchIdOf(widget.branches.first) : null);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  static int? _branchIdOf(Map<String, dynamic> branch) {
    final raw = branch['id'] ?? branch['branch_id'];
    return raw is int ? raw : int.tryParse(raw?.toString() ?? '');
  }

  static String _branchNameOf(Map<String, dynamic> branch) =>
      (branch['name'] ?? branch['branch_name'] ?? S.unknown).toString();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final branchId = _branchId;
    if (branchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.noBranchSelected)),
      );
      return;
    }

    final result = await context.read<FinanceProvider>().createExpense(
          title: _titleController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          branchId: branchId,
          expenseDate: _date,
          category: _category,
          description: _descriptionController.text.trim(),
        );

    if (!mounted) return;

    if (result['success'] == true) {
      widget.onRecorded?.call();
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.expenseRecorded),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? S.unexpectedError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.watch<FinanceProvider>().isSubmitting;
    final showBranchPicker = widget.branches.length > 1;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.money_off, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(S.recordExpense)),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: S.expenseTitle,
                    prefixIcon: const Icon(Icons.description_outlined),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? S.required : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: S.amountRequired,
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final amount = double.tryParse(v?.trim() ?? '');
                    if (amount == null) return S.required;
                    if (amount <= 0) return S.required;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _category,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: S.expenseCategory,
                    prefixIcon: const Icon(Icons.category_outlined),
                  ),
                  items: [
                    for (final category in ExpenseCategories.all)
                      DropdownMenuItem(
                        value: category,
                        child: Text(S.expenseCategoryLabel(category)),
                      ),
                  ],
                  onChanged: (v) => setState(() => _category = v!),
                ),
                if (showBranchPicker) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _branchId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: S.branchRequired,
                      prefixIcon: const Icon(Icons.store_outlined),
                    ),
                    items: [
                      for (final branch in widget.branches)
                        if (_branchIdOf(branch) != null)
                          DropdownMenuItem(
                            value: _branchIdOf(branch),
                            child: Text(_branchNameOf(branch)),
                          ),
                    ],
                    onChanged: (v) => setState(() => _branchId = v),
                    validator: (v) => v == null ? S.noBranchSelected : null,
                  ),
                ],
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: S.expenseDate,
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(DateHelper.formatDate(_date)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: S.notes,
                    prefixIcon: const Icon(Icons.notes_outlined),
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting ? null : () => Navigator.pop(context),
          child: Text(S.cancel),
        ),
        ElevatedButton(
          onPressed: isSubmitting ? null : _submit,
          child: isSubmitting ? const SmallLoadingIndicator() : Text(S.save),
        ),
      ],
    );
  }
}
