import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/utils/helpers.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../core/api/client_api_service.dart';
import '../core/theme/client_theme.dart';

/// Every subscription the member has taken, what they paid for each one, and
/// the running total across all of them.
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _subscriptions = [];
  List<Map<String, dynamic>> _otherPayments = [];
  double _totalPaid = 0;
  double _otherTotal = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await context.read<ClientApiService>().getPayments();
      if (response['success'] == true || response['status'] == 'success') {
        final data = Map<String, dynamic>.from(response['data'] ?? {});
        setState(() {
          _subscriptions = _mapList(data['subscriptions']);
          _otherPayments = _mapList(data['other_payments']);
          _totalPaid = _toDouble(data['total_paid']);
          _otherTotal = _toDouble(data['other_total']);
        });
      } else {
        setState(() => _error = response['message'] ?? response['error']);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static List<Map<String, dynamic>> _mapList(dynamic raw) =>
      (raw as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  static double _toDouble(dynamic raw) => (raw as num?)?.toDouble() ?? 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientTheme.darkGrey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(S.myPayments),
      ),
      body: _isLoading
          ? const DashboardSkeleton()
          : _error != null
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: ClientTheme.primaryRed,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _totalCard(),
                      const SizedBox(height: 20),
                      if (_subscriptions.isEmpty && _otherPayments.isEmpty)
                        _emptyView()
                      else ...[
                        if (_subscriptions.isNotEmpty) ...[
                          _sectionTitle(S.paymentsAndSubscriptions),
                          const SizedBox(height: 10),
                          for (final subscription in _subscriptions) ...[
                            _subscriptionCard(subscription),
                            const SizedBox(height: 12),
                          ],
                        ],
                        if (_otherPayments.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _sectionTitle(S.otherPayments),
                          const SizedBox(height: 10),
                          _otherPaymentsCard(),
                        ],
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _totalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ClientTheme.primaryRed,
            ClientTheme.primaryRed.withValues(alpha: 0.72),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ClientTheme.primaryRed.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.totalPaid,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              NumberHelper.formatCurrency(_totalPaid),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${S.totalPaidAllTime} · ${S.subscriptionsCountLabel(_subscriptions.length)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          color: ClientTheme.textWhite,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      );

  Widget _subscriptionCard(Map<String, dynamic> subscription) {
    final payments = _mapList(subscription['payments']);
    final totalPaid = _toDouble(subscription['total_paid']);
    final status = (subscription['status'] ?? '').toString();
    final statusColor = _statusColor(status);
    final name = (subscription['service_name'] ??
            subscription['subscription_type'] ??
            S.subscriptionDetails)
        .toString();

    return Container(
      decoration: BoxDecoration(
        color: ClientTheme.cardGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: ClientTheme.textWhite,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dateRange(subscription),
                        style: const TextStyle(
                          color: ClientTheme.subtleGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberHelper.formatCurrency(totalPaid),
                      style: const TextStyle(
                        color: ClientTheme.textWhite,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      S.paidForThisSubscription,
                      style: const TextStyle(
                        color: ClientTheme.subtleGrey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF243050)),
          if (payments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                S.noPaymentsRecorded,
                style: const TextStyle(
                    color: ClientTheme.subtleGrey, fontSize: 12),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [for (final payment in payments) _paymentRow(payment)],
              ),
            ),
        ],
      ),
    );
  }

  Widget _otherPaymentsCard() {
    return Container(
      decoration: BoxDecoration(
        color: ClientTheme.cardGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    S.paymentsCountLabel(_otherPayments.length),
                    style: const TextStyle(
                      color: ClientTheme.textGrey,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  NumberHelper.formatCurrency(_otherTotal),
                  style: const TextStyle(
                    color: ClientTheme.textWhite,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF243050)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: [for (final payment in _otherPayments) _paymentRow(payment)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentRow(Map<String, dynamic> payment) {
    final amount = _toDouble(payment['amount']);
    final discount = _toDouble(payment['discount']);
    final method = (payment['payment_method'] ?? '').toString();
    final date = _formatDate(payment['date']);

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _methodColor(method).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(_methodIcon(method), size: 16, color: _methodColor(method)),
      ),
      title: Text(
        date,
        style: const TextStyle(
          color: ClientTheme.textWhite,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        [
          if (method.isNotEmpty) _methodLabel(method),
          if (discount > 0) '${S.discountLabel} ${NumberHelper.formatCurrency(discount)}',
        ].join(' · '),
        style: const TextStyle(color: ClientTheme.subtleGrey, fontSize: 11),
      ),
      trailing: Text(
        NumberHelper.formatCurrency(amount),
        style: const TextStyle(
          color: Color(0xFF10B981),
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _emptyView() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 60, color: ClientTheme.subtleGrey),
            const SizedBox(height: 14),
            Text(
              S.noPaymentsYet,
              style: const TextStyle(color: ClientTheme.textGrey, fontSize: 15),
            ),
          ],
        ),
      );

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 14),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: Text(S.retry)),
            ],
          ),
        ),
      );

  String _dateRange(Map<String, dynamic> subscription) {
    final start = _formatDate(subscription['start_date']);
    final end = _formatDate(subscription['end_date']);
    if (start.isEmpty) return end;
    if (end.isEmpty) return start;
    return '$start → $end';
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return raw.toString();
    return DateHelper.formatDate(parsed);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF10B981);
      case 'frozen':
        return const Color(0xFF4C6FFF);
      case 'stopped':
        return Colors.redAccent;
      default:
        return ClientTheme.subtleGrey;
    }
  }

  Color _methodColor(String method) {
    switch (method.toLowerCase()) {
      case 'network':
      case 'card':
        return const Color(0xFF4C6FFF);
      case 'transfer':
        return const Color(0xFF9B6BFF);
      default:
        return const Color(0xFF10B981);
    }
  }

  IconData _methodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'network':
      case 'card':
        return Icons.credit_card;
      case 'transfer':
        return Icons.send;
      default:
        return Icons.payments;
    }
  }

  String _methodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'network':
      case 'card':
        return S.card;
      case 'transfer':
        return S.transfer;
      case 'cash':
        return S.cash;
      default:
        return method;
    }
  }
}
