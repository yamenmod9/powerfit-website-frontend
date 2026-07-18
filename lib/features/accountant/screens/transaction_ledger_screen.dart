import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/providers/gym_branding_provider.dart';
import '../../finance/services/receipt_actions.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/api_endpoints.dart';

class TransactionLedgerScreen extends StatefulWidget {
  final int? branchId;

  const TransactionLedgerScreen({super.key, this.branchId});

  @override
  State<TransactionLedgerScreen> createState() => _TransactionLedgerScreenState();
}

class _TransactionLedgerScreenState extends State<TransactionLedgerScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _transactions = [];
  Map<String, dynamic> _summary = {};

  // Filters
  DateTime _selectedDate = DateTime.now();
  String? _selectedPaymentMethod;
  String _searchQuery = '';

  /// The transaction whose receipt is currently being fetched/rendered, so only
  /// that row shows a spinner.
  int? _receiptBusyId;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();

      // Use /api/reports/daily which returns individual transactions
      final response = await apiService.get(
        ApiEndpoints.reportsDaily,
        queryParameters: {
          'date': _selectedDate.toIso8601String().split('T')[0],
          if (widget.branchId != null) 'branch_id': widget.branchId,
        },
      );

      debugPrint('📋 Ledger response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final d = response.data['data'] ?? response.data;
        setState(() {
          _transactions = List<dynamic>.from(d['transactions'] ?? []);
          _summary = {
            'total_revenue': (d['total_revenue'] ?? 0).toDouble(),
            'total_transactions': d['total_transactions'] ?? _transactions.length,
            'total_discount': (d['total_discount'] ?? 0).toDouble(),
            'new_subscriptions': d['new_subscriptions'] ?? 0,
            'payment_breakdown': d['payment_breakdown'] ?? {},
          };
          _isLoading = false;
        });
        debugPrint('✅ Ledger loaded: ${_transactions.length} transactions');
      } else {
        setState(() {
          _error = 'Failed to load transactions (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Ledger error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredTransactions {
    var list = _transactions;

    // Payment method filter
    if (_selectedPaymentMethod != null) {
      list = list.where((tx) {
        final method = (tx['payment_method'] ?? '').toString().toLowerCase();
        return method == _selectedPaymentMethod!.toLowerCase();
      }).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      list = list.where((tx) {
        final customerName = (tx['customer_name'] ?? '').toString().toLowerCase();
        final id = (tx['id'] ?? '').toString();
        final query = _searchQuery.toLowerCase();
        return customerName.contains(query) || id.contains(query);
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.transactionLedger),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: S.changeDate,
            onPressed: _pickDate,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date indicator + summary
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          DateHelper.formatDate(_selectedDate),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (!_isLoading && _error == null)
                  Text(
                    S.transactionsCountLabel(_filteredTransactions.length),
                    style: TextStyle(color: Color(0xFF6B7590), fontSize: 13),
                  ),
              ],
            ),
          ),

          // Summary cards
          if (!_isLoading && _error == null && _summary.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                children: [
                  Expanded(child: _buildSummaryChip(S.revenue,
                    NumberHelper.formatCurrency((_summary['total_revenue'] ?? 0).toDouble()),
                    Colors.green)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSummaryChip(S.cash,
                    NumberHelper.formatCurrency(((_summary['payment_breakdown'] ?? {})['cash'] ?? 0).toDouble()),
                    Colors.teal)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSummaryChip(S.card,
                    NumberHelper.formatCurrency(((_summary['payment_breakdown'] ?? {})['network'] ?? 0).toDouble()),
                    Colors.blue)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSummaryChip(S.transfer,
                    NumberHelper.formatCurrency(((_summary['payment_breakdown'] ?? {})['transfer'] ?? 0).toDouble()),
                    Colors.purple)),
                ],
              ),
            ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: S.searchByCustomer,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Active filter chips
          if (_selectedPaymentMethod != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Chip(
                    label: Text(S.paymentFilter(_selectedPaymentMethod ?? S.allMethods)),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => setState(() => _selectedPaymentMethod = null),
                  ),
                ],
              ),
            ),

          // Transaction list
          Expanded(
            child: _isLoading
                ? const DashboardSkeleton()
                : _error != null
                    ? ErrorDisplay(message: _error!, onRetry: _loadTransactions)
                    : _filteredTransactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long, size: 64, color: Color(0xFF9AA3B8)),
                                const SizedBox(height: 16),
                                Text(S.noTransactionsForDate,
                                  style: TextStyle(fontSize: 16, color: Color(0xFF9AA3B8))),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: _pickDate,
                                  icon: const Icon(Icons.calendar_today, size: 16),
                                  label: Text(S.pickAnotherDate),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadTransactions,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: _filteredTransactions.length,
                              itemBuilder: (context, index) {
                                final tx = _filteredTransactions[index];
                                return _buildTransactionCard(tx);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Color(0xFF6B7590))),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(dynamic tx) {
    final id = tx['id'] ?? 0;
    final customerName = tx['customer_name'] ?? S.walkIn;
    final amount = (tx['amount'] ?? 0).toDouble();
    final discount = (tx['discount'] ?? 0).toDouble();
    final netAmount = amount - discount;
    final paymentMethod = (tx['payment_method'] ?? 'cash').toString();
    final time = tx['time'] ?? '';

    Color methodColor;
    IconData methodIcon;
    switch (paymentMethod.toLowerCase()) {
      case 'network':
      case 'card':
        methodColor = Colors.blue;
        methodIcon = Icons.credit_card;
        break;
      case 'transfer':
      case 'online':
        methodColor = Colors.purple;
        methodIcon = Icons.send;
        break;
      default:
        methodColor = Colors.green;
        methodIcon = Icons.payments;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: methodColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(methodIcon, color: methodColor, size: 22),
        ),
        title: Text(customerName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: methodColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(paymentMethod,
                style: TextStyle(fontSize: 10, color: methodColor, fontWeight: FontWeight.w500)),
            ),
            if (time.isNotEmpty) ...[
              const SizedBox(width: 8),
              Icon(Icons.access_time, size: 12, color: Color(0xFF9AA3B8)),
              const SizedBox(width: 2),
              Text(time, style: TextStyle(fontSize: 11, color: Color(0xFF9AA3B8))),
            ],
          ],
        ),
        trailing: Text(
          NumberHelper.formatCurrency(netAmount),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                const Divider(),
                _buildDetailRow(S.transactionNumber(id), '#$id'),
                const SizedBox(height: 6),
                _buildDetailRow(S.grossAmount, NumberHelper.formatCurrency(amount)),
                if (discount > 0) ...[
                  const SizedBox(height: 6),
                  _buildDetailRow(S.discount, '- ${NumberHelper.formatCurrency(discount)}'),
                ],
                const SizedBox(height: 6),
                _buildDetailRow(S.netAmount, NumberHelper.formatCurrency(netAmount)),
                const SizedBox(height: 6),
                _buildDetailRow(S.payment, S.paymentMethodLabel(paymentMethod)),
                if (time.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildDetailRow(S.time, time),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _receiptBusyId == id ? null : () => _printReceipt(tx),
                    icon: _receiptBusyId == id
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.receipt_long, size: 18),
                    label: Text(S.printOrShareReceipt),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fetches the full transaction, renders the receipt, and hands it to the
  /// platform's print/share sheet.
  ///
  /// The ledger rows come from /reports/daily, which carries only a summary —
  /// the receipt needs the branch header and member name, so the record is
  /// fetched on demand rather than bloating every row.
  Future<void> _printReceipt(dynamic tx) async {
    final id = (tx['id'] as num?)?.toInt();
    if (id == null) return;

    final apiService = context.read<ApiService>();
    final gymName = context.read<GymBrandingProvider>().gymName;

    setState(() => _receiptBusyId = id);
    try {
      final response = await apiService.get(ApiEndpoints.transactionById(id));
      if (!mounted) return;

      if (response.statusCode != 200 || response.data == null) {
        _showReceiptError();
        return;
      }

      final data = Map<String, dynamic>.from(
        (response.data['data'] ?? response.data) as Map,
      );
      if (!mounted) return;

      // Offer both print and share rather than jumping straight to print.
      await ReceiptActions.show(context, transaction: data, gymName: gymName);
    } catch (e) {
      debugPrint('❌ Receipt failed: $e');
      if (mounted) _showReceiptError();
    } finally {
      if (mounted) setState(() => _receiptBusyId = null);
    }
  }

  void _showReceiptError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(S.receiptFailed),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Color(0xFF6B7590), fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadTransactions();
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.filterTransactions),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.paymentMethod, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: S.allMethods,
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(S.allMethods)),
                DropdownMenuItem(value: 'cash', child: Text(S.cash)),
                DropdownMenuItem(value: 'network', child: Text(S.networkCard)),
                DropdownMenuItem(value: 'transfer', child: Text(S.transfer)),
              ],
              onChanged: (value) {
                _selectedPaymentMethod = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selectedPaymentMethod = null);
              Navigator.pop(ctx);
            },
            child: Text(S.clear),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(ctx);
            },
            child: Text(S.apply),
          ),
        ],
      ),
    );
  }
}
