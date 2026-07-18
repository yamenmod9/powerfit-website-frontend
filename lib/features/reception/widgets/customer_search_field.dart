import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/models/customer_model.dart';
import '../providers/reception_provider.dart';

/// Type-ahead member picker for front-desk forms.
///
/// The desk rarely knows a member's ID — they have a name, a phone, or an
/// email. Typing any of those (or the ID) searches as you go and drops down
/// the matches to pick from, so nothing has to be typed in full.
class CustomerSearchField extends StatefulWidget {
  final CustomerModel? selected;
  final ValueChanged<CustomerModel?> onSelected;
  final String? labelText;

  const CustomerSearchField({
    super.key,
    required this.selected,
    required this.onSelected,
    this.labelText,
  });

  @override
  State<CustomerSearchField> createState() => _CustomerSearchFieldState();
}

class _CustomerSearchFieldState extends State<CustomerSearchField> {
  static const _debounce = Duration(milliseconds: 300);

  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  Timer? _debounceTimer;
  List<CustomerModel> _results = [];
  bool _isSearching = false;

  /// Guards against a slow earlier request overwriting a newer one's results.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // Editing the query invalidates whoever was picked from the last one.
    if (widget.selected != null) widget.onSelected(null);

    _debounceTimer?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounceTimer = Timer(_debounce, () => _search(query));
  }

  Future<void> _search(String query) async {
    final requestId = ++_requestId;
    final results = await context.read<ReceptionProvider>().searchCustomers(query);
    if (!mounted || requestId != _requestId) return;
    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  void _select(CustomerModel customer) {
    _controller.text = customer.fullName;
    setState(() => _results = []);
    widget.onSelected(customer);
    // Drop focus AFTER the selection is committed. Unfocusing first would
    // rebuild with the panel gone before this tap's onTap could run — the
    // classic "clicking a result does nothing" bug on Flutter web.
    _focusNode.unfocus();
  }

  void _clear() {
    _controller.clear();
    setState(() => _results = []);
    widget.onSelected(null);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    if (selected != null) return _selectedCard(selected);

    // Show the results while there is a query and something to show — NOT
    // gated on focus. On web, clicking a result blurs the field first, and a
    // focus-gated panel would unmount before the click's onTap fired, so the
    // selection silently never happened. Decoupling from focus fixes it.
    final showPanel = _controller.text.trim().isNotEmpty &&
        (_isSearching || _results.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: widget.labelText ?? S.customerRequired,
            hintText: S.searchCustomerHint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _clear,
                  ),
          ),
          validator: (_) => widget.selected == null ? S.pleaseSelectCustomer : null,
        ),
        if (showPanel) _resultsPanel(),
      ],
    );
  }

  Widget _resultsPanel() {
    // A Material (not a decorated Container) so the rows' tap ink stays
    // visible — ListTile paints its splash on the nearest Material ancestor.
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 210),
      child: Material(
        color: Theme.of(context).cardColor,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF243050)),
        ),
        child: _isSearching
            ? _hint(S.searching, leading: const _TinySpinner())
            : _results.isEmpty
                ? _hint(S.noCustomersMatch)
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _results.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: Color(0xFF243050)),
                    itemBuilder: (context, index) => _resultTile(_results[index]),
                  ),
      ),
    );
  }

  Widget _resultTile(CustomerModel customer) {
    final subtitle = [
      if (customer.id != null) S.customerIdLabel(customer.id!),
      if (customer.phone?.isNotEmpty ?? false) customer.phone!,
      if (customer.email?.isNotEmpty ?? false) customer.email!,
    ].join(' · ');

    return ListTile(
      dense: true,
      onTap: () => _select(customer),
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        child: Text(
          customer.fullName.isNotEmpty ? customer.fullName[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      title: Text(
        customer.fullName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle.isEmpty
          ? null
          : Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF9AA3B8)),
            ),
    );
  }

  Widget _selectedCard(CustomerModel customer) {
    final subtitle = [
      if (customer.id != null) S.customerIdLabel(customer.id!),
      if (customer.phone?.isNotEmpty ?? false) customer.phone!,
    ].join(' · ');
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: accent.withValues(alpha: 0.18),
            child: Text(
              customer.fullName.isNotEmpty ? customer.fullName[0].toUpperCase() : '?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: accent),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF9AA3B8)),
                  ),
              ],
            ),
          ),
          TextButton(onPressed: _clear, child: Text(S.changeSelection)),
        ],
      ),
    );
  }

  Widget _hint(String text, {Widget? leading}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          children: [
            if (leading != null) ...[leading, const SizedBox(width: 10)],
            Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF9AA3B8))),
          ],
        ),
      );
}

class _TinySpinner extends StatelessWidget {
  const _TinySpinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
}
