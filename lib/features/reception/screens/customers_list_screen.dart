import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../providers/reception_provider.dart';
import '../../../core/localization/app_strings.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchController.addListener(_filterCustomers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<ReceptionProvider>();
      final customers = await provider.getAllCustomersWithCredentials();

      // Check mounted again after async operation
      if (!mounted) return;

      setState(() {
        _customers = customers;
        _filteredCustomers = customers;
        _isLoading = false;
      });
    } catch (e) {
      // Check mounted before showing error
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${S.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterCustomers() {
    if (!mounted) return;
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = _customers;
      } else {
        _filteredCustomers = _customers.where((customer) {
          final name = customer['full_name']?.toString().toLowerCase() ?? '';
          final phone = customer['phone']?.toString().toLowerCase() ?? '';
          final email = customer['email']?.toString().toLowerCase() ?? '';
          return name.contains(query) || phone.contains(query) || email.contains(query);
        }).toList();
      }
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(S.copiedToClipboard(label)),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.allCustomers),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: S.searchCustomers,
                hintText: S.namePhoneEmail,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  S.customersCountLabel(_filteredCustomers.length),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Customer list
          Expanded(
            child: _isLoading
                ? const DashboardSkeleton()
                : _filteredCustomers.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? S.noCustomersFound
                              : S.noCustomersMatch,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadCustomers,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 80), // Extra bottom padding for navbar
                          itemCount: _filteredCustomers.length,
                          itemBuilder: (context, index) {
                            final customer = _filteredCustomers[index];
                            return _buildCustomerCard(customer);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    final name = customer['full_name'] ?? S.unknown;
    final phone = customer['phone'] ?? S.na;
    final email = customer['email'] ?? S.na;
    final qrCode = customer['qr_code'] ?? S.na;
    // Extract temporary password - backend should return this for staff when password_changed is false
    final tempPassword = customer['temporary_password'] ?? customer['temp_password'] ?? S.notAvailable;
    final hasActiveSubRaw = customer['has_active_subscription'];
    final activeSubsCountRaw = customer['active_subscriptions_count'] ??
        customer['activeSubscriptionsCount'] ??
        customer['subscriptions_count'];
    final activeSubsCount = activeSubsCountRaw is num
        ? activeSubsCountRaw.toInt()
        : int.tryParse(activeSubsCountRaw?.toString() ?? '') ?? 0;
    final hasActiveSub = hasActiveSubRaw == true ||
      hasActiveSubRaw == 1 ||
      hasActiveSubRaw?.toString().toLowerCase() == 'true' ||
      hasActiveSubRaw?.toString() == '1' ||
      activeSubsCount > 0;
    final customerId = customer['id'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: hasActiveSub ? Colors.green : Colors.orange,
          child: Icon(
            hasActiveSub ? Icons.check_circle : Icons.warning,
            color: Colors.white,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${S.customerId(customerId)} • ${hasActiveSub ? S.active : S.noSubscription}',
          style: TextStyle(
            color: hasActiveSub ? Colors.green : Colors.orange,
          ),
        ),
        children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contact Info
                _buildInfoRow(
                  S.phone,
                  phone,
                  Icons.phone,
                  onTap: () => _copyToClipboard(phone, S.phone),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  S.email,
                  email,
                  Icons.email,
                  onTap: () => _copyToClipboard(email, S.email),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  S.qrCode,
                  qrCode,
                  Icons.qr_code,
                  onTap: () => _copyToClipboard(qrCode, S.qrCode),
                ),
                const Divider(height: 24),

                // Login Credentials Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lock,
                            size: 20,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            S.clientAppCredentials,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildCredentialRow(
                        S.login,
                        phone.isNotEmpty && phone != 'N/A' ? phone : email,
                        Icons.person,
                      ),
                      const SizedBox(height: 8),
                      _buildCredentialRow(
                        S.password,
                        tempPassword == S.notAvailable ? S.notAvailable : tempPassword,
                        Icons.password,
                        isPassword: true,
                        showCopy: tempPassword != S.notAvailable,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            tempPassword == S.notAvailable
                                ? Icons.warning_amber
                                : Icons.info_outline,
                            size: 16,
                            color: tempPassword == S.notAvailable
                                ? Colors.red
                                : Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tempPassword == S.notAvailable
                                  ? S.passwordNotReturned
                                  : S.permanentLoginPassword,
                              style: TextStyle(
                                fontSize: 12,
                                color: tempPassword == S.notAvailable
                                    ? Colors.red
                                    : Colors.blue,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Color(0xFF9AA3B8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF6B7590),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(Icons.copy, size: 16, color: const Color(0xFF9AA3B8)),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value, IconData icon,
      {bool isPassword = false, bool showCopy = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: isPassword ? 'monospace' : null,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
        ),
        if (showCopy)
          IconButton(
            icon: Icon(Icons.copy, size: 18, color: Colors.blue.shade700),
            onPressed: () => _copyToClipboard(value, label),
            tooltip: S.copyLabel(label),
          ),
      ],
    );
  }
}

