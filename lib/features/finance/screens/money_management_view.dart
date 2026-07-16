import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/dashboard_shell.dart';
import '../providers/finance_provider.dart';
import '../widgets/record_expense_dialog.dart';

/// The money page shared by the owner and accountant consoles: what came in,
/// what went out, and the entry point for recording new spending.
///
/// It renders whatever its host already loaded — [earnings] and [expenses]
/// come from the role's own provider — and owns only the write actions, so
/// both roles behave identically without sharing a read path.
class MoneyManagementView extends StatelessWidget {
  /// Money in for the period.
  final double earnings;

  /// Raw expense records (as returned by /api/finance/expenses).
  final List<dynamic> expenses;

  /// Branches this user may file an expense against.
  final List<Map<String, dynamic>> branches;

  /// Preselected branch — branch-scoped staff have exactly one.
  final int? defaultBranchId;

  /// Whether to show approve/reject controls on pending expenses.
  final bool canReview;

  final Future<void> Function() onRefresh;

  const MoneyManagementView({
    super.key,
    required this.earnings,
    required this.expenses,
    required this.branches,
    required this.onRefresh,
    this.defaultBranchId,
    this.canReview = false,
  });

  static double _amountOf(dynamic expense) =>
      ((expense['amount'] ?? 0) as num).toDouble();

  static String _statusOf(dynamic expense) =>
      (expense['status'] ?? 'pending').toString().toLowerCase();

  List<dynamic> get _pending =>
      expenses.where((e) => _statusOf(e) == 'pending').toList();

  List<dynamic> get _approved =>
      expenses.where((e) => _statusOf(e) == 'approved').toList();

  double get _approvedTotal =>
      _approved.fold(0.0, (sum, e) => sum + _amountOf(e));

  double get _pendingTotal =>
      _pending.fold(0.0, (sum, e) => sum + _amountOf(e));

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final net = earnings - _approvedTotal;

    return Stack(
      children: [
        DashBody(
          onRefresh: onRefresh,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashKpiGrid(cards: [
                DashKpiCard(
                  label: S.moneyIn,
                  value: NumberHelper.formatCurrency(earnings),
                  icon: Icons.trending_up,
                  iconColor: DashColors.emerald,
                  valueColor: DashColors.emerald,
                  sub: S.earnings,
                ),
                DashKpiCard(
                  label: S.moneyOut,
                  value: NumberHelper.formatCurrency(_approvedTotal),
                  icon: Icons.trending_down,
                  iconColor: Colors.redAccent,
                  sub: S.approvedExpenses,
                ),
                DashKpiCard(
                  label: S.netBalance,
                  value: NumberHelper.formatCurrency(net),
                  icon: Icons.account_balance_wallet,
                  iconColor: net >= 0 ? DashColors.blue : Colors.redAccent,
                  valueColor: net >= 0 ? null : Colors.redAccent,
                  sub: S.pendingExcludedFromNet,
                ),
                DashKpiCard(
                  label: S.pendingApproval,
                  value: NumberHelper.formatCurrency(_pendingTotal),
                  icon: Icons.pending_actions,
                  iconColor: DashColors.amber,
                  sub: S.expensesCountLabel(_pending.length),
                ),
              ]),
              const SizedBox(height: 20),
              if (_pending.isNotEmpty) ...[
                DashSectionCard(
                  title: S.pendingApproval,
                  accent: accent,
                  child: Column(
                    children: [
                      for (var i = 0; i < _pending.length; i++) ...[
                        _expenseTile(context, _pending[i]),
                        if (i < _pending.length - 1) const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
              DashSectionCard(
                title: S.expenses,
                accent: accent,
                actionLabel: S.addExpense,
                onAction: () => _openRecordDialog(context),
                child: expenses.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 26),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.receipt_long_outlined,
                                  size: 40, color: DashColors.subtle),
                              const SizedBox(height: 10),
                              Text(
                                S.noExpensesFound,
                                style: const TextStyle(
                                    color: DashColors.subtle, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < expenses.length; i++) ...[
                            _expenseTile(context, expenses[i]),
                            if (i < expenses.length - 1)
                              const SizedBox(height: 10),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
        PositionedDirectional(
          end: 20,
          bottom: 20,
          child: FloatingActionButton.extended(
            heroTag: 'record-expense',
            onPressed: () => _openRecordDialog(context),
            icon: const Icon(Icons.add),
            label: Text(S.recordExpense),
          ),
        ),
      ],
    );
  }

  Future<void> _openRecordDialog(BuildContext context) async {
    final recorded = await showDialog<bool>(
      context: context,
      builder: (_) => RecordExpenseDialog(
        branches: branches,
        defaultBranchId: defaultBranchId,
      ),
    );
    if (recorded == true) await onRefresh();
  }

  Widget _expenseTile(BuildContext context, dynamic expense) {
    final status = _statusOf(expense);
    final amount = _amountOf(expense);
    final title =
        (expense['title'] ?? expense['description'] ?? S.expenses).toString();
    final category = (expense['category'] ?? '').toString();
    final branchName = (expense['branch_name'] ?? '').toString();
    final createdBy = (expense['created_by_name'] ?? '').toString();
    final date = (expense['expense_date'] ?? expense['created_at'] ?? '').toString();

    final (statusColor, statusIcon) = switch (status) {
      'approved' => (DashColors.emerald, Icons.check_circle),
      'rejected' => (Colors.redAccent, Icons.cancel),
      _ => (DashColors.amber, Icons.hourglass_top),
    };

    final meta = [
      if (category.isNotEmpty) S.expenseCategoryLabel(category),
      if (branchName.isNotEmpty) branchName,
      if (date.isNotEmpty) _formatDate(date),
      if (createdBy.isNotEmpty) createdBy,
    ].join(' · ');

    final showReview = canReview && status == 'pending';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashColors.inner,
        borderRadius: BorderRadius.circular(12),
        border: BorderDirectional(
          start: BorderSide(color: statusColor, width: 3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (meta.isNotEmpty)
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: DashColors.subtle, fontSize: 11.5),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                NumberHelper.formatCurrency(amount),
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (showReview) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _review(context, expense, approve: false),
                  icon: const Icon(Icons.close, size: 16),
                  label: Text(S.reject),
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  onPressed: () => _review(context, expense, approve: true),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(S.approve),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DashColors.emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _review(
    BuildContext context,
    dynamic expense, {
    required bool approve,
  }) async {
    final id = expense['id'] is int
        ? expense['id'] as int
        : int.tryParse(expense['id']?.toString() ?? '');
    if (id == null) return;

    // Resolved up front: the rejection prompt below is an async gap, after
    // which this context may no longer be mounted.
    final messenger = ScaffoldMessenger.of(context);
    final finance = context.read<FinanceProvider>();

    String? notes;
    if (!approve) {
      notes = await _askRejectionReason(context);
      if (notes == null) return; // cancelled
    }

    final result = await finance.reviewExpense(
      expenseId: id,
      approve: approve,
      notes: notes,
    );

    if (result['success'] == true) {
      await onRefresh();
      messenger.showSnackBar(
        SnackBar(
          content: Text(approve ? S.expenseApproved : S.expenseRejected),
          backgroundColor: approve ? Colors.green : Colors.orange,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? S.unexpectedError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _askRejectionReason(BuildContext context) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.reject),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLines: 2,
            decoration: InputDecoration(labelText: S.rejectionReason),
            validator: (v) =>
                (v?.trim().isEmpty ?? true) ? S.rejectionReasonRequired : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(S.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: Text(S.reject),
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    return parsed == null ? raw : DateHelper.formatDate(parsed);
  }
}
