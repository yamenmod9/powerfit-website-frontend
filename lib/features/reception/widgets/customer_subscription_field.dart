import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/models/customer_model.dart';
import '../providers/reception_provider.dart';
import 'customer_search_field.dart';

/// Pick a member by name, then pick which of their subscriptions to act on.
///
/// The renew/freeze/stop flows used to demand a raw subscription ID typed
/// from memory — unusable at a busy desk. This resolves the member first,
/// loads their subscriptions, and hands back the chosen subscription id.
class CustomerSubscriptionField extends StatefulWidget {
  /// Called with the selected subscription id, or null when the selection is
  /// cleared or incomplete.
  final ValueChanged<int?> onSubscriptionSelected;

  /// When set, only subscriptions whose (lower-cased) status is in this set
  /// are offered — e.g. {'active', 'frozen'} for freeze/stop.
  final Set<String>? allowedStatuses;

  const CustomerSubscriptionField({
    super.key,
    required this.onSubscriptionSelected,
    this.allowedStatuses,
  });

  @override
  State<CustomerSubscriptionField> createState() =>
      _CustomerSubscriptionFieldState();
}

class _CustomerSubscriptionFieldState extends State<CustomerSubscriptionField> {
  CustomerModel? _customer;
  List<Map<String, dynamic>> _subscriptions = [];
  int? _selectedSubscriptionId;
  bool _loading = false;

  Future<void> _onCustomerSelected(CustomerModel? customer) async {
    setState(() {
      _customer = customer;
      _subscriptions = [];
      _selectedSubscriptionId = null;
      _loading = customer != null;
    });
    widget.onSubscriptionSelected(null);

    if (customer?.id == null) return;

    final all = await context
        .read<ReceptionProvider>()
        .fetchCustomerSubscriptions(customer!.id!);
    if (!mounted) return;

    final filtered = widget.allowedStatuses == null
        ? all
        : all
            .where((s) => widget.allowedStatuses!
                .contains((s['status'] ?? '').toString().toLowerCase()))
            .toList();

    setState(() {
      _subscriptions = filtered;
      _loading = false;
      // Auto-select when there's exactly one candidate — the common case.
      if (filtered.length == 1) {
        _selectedSubscriptionId = filtered.first['id'] as int?;
      }
    });
    widget.onSubscriptionSelected(_selectedSubscriptionId);
  }

  String _label(Map<String, dynamic> sub) {
    final service = sub['service_name'] ??
        sub['service']?['name'] ??
        S.subscription;
    final status = (sub['status'] ?? '').toString();
    final end = (sub['end_date'] ?? '').toString().split('T').first;
    final parts = [
      '#${sub['id']}',
      service.toString(),
      if (status.isNotEmpty) status,
      if (end.isNotEmpty) '→ $end',
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomerSearchField(
          selected: _customer,
          onSelected: _onCustomerSelected,
        ),
        const SizedBox(height: 12),
        if (_customer != null) ...[
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_subscriptions.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(S.noSubscriptionsForMember)),
                ],
              ),
            )
          else
            DropdownButtonFormField<int>(
              value: _selectedSubscriptionId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: S.subscriptionRequired,
                prefixIcon: const Icon(Icons.card_membership),
              ),
              items: _subscriptions
                  .map((sub) => DropdownMenuItem<int>(
                        value: sub['id'] as int?,
                        child: Text(
                          _label(sub),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (id) {
                setState(() => _selectedSubscriptionId = id);
                widget.onSubscriptionSelected(id);
              },
              validator: (v) => v == null ? S.pleaseSelectSubscription : null,
            ),
        ],
      ],
    );
  }
}
