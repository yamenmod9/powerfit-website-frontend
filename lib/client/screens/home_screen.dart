import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/app_strings.dart';
import '../core/auth/client_auth_provider.dart';
import '../core/api/client_api_service.dart';
import '../models/subscription_model.dart';
import '../../shared/widgets/skeleton_loader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SubscriptionModel? _subscription;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('🏠 Loading subscription data...');
      final apiService = context.read<ClientApiService>();
      
      // Use getProfile() which returns client data including subscription
      // instead of getSubscription() which might not exist
      final response = await apiService.getProfile();

      debugPrint('🏠 Profile API Response: $response');
      debugPrint('🏠 Response keys: ${response.keys.toList()}');

      // Check for different response formats
      bool isSuccess = false;
      if (response.containsKey('success')) {
        isSuccess = response['success'] == true;
      } else if (response.containsKey('status')) {
        isSuccess = response['status'] == 'success';
      }

      if (isSuccess && response['data'] != null) {
        final data = response['data'];
        debugPrint('🏠 Profile data keys: ${data.keys.toList()}');
        
        // Check if profile has active_subscription or subscription field
        if (data['active_subscription'] != null) {
          debugPrint('🏠 Parsing active_subscription data: ${data['active_subscription']}');
          setState(() {
            _subscription = SubscriptionModel.fromJson(data['active_subscription']);
          });
          debugPrint('✅ Subscription loaded successfully');
        } else if (data['subscription'] != null) {
          debugPrint('🏠 Parsing subscription data: ${data['subscription']}');
          setState(() {
            _subscription = SubscriptionModel.fromJson(data['subscription']);
          });
          debugPrint('✅ Subscription loaded successfully');
        } else {
          debugPrint('⚠️ No active_subscription or subscription field found');
          setState(() {
            _error = S.noActiveSubFound;
          });
        }
      } else {
        final errorMsg = response['message'] ?? S.error;
        debugPrint('⚠️ Profile load failed: $errorMsg');
        setState(() {
          _error = errorMsg;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading subscription: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      
      // Check if it's a 404 error
      String errorMsg = e.toString();
      if (errorMsg.contains('404')) {
        errorMsg = S.subEndpointNotAvailable;
      }
      
      setState(() {
        _error = errorMsg;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = context.watch<ClientAuthProvider>().currentClient;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.dashboard),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.goNamed('settings'),
            tooltip: S.settings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSubscription,
        child: _isLoading
            ? const DashboardSkeleton()
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadSubscription,
                          child: Text(S.retry),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Welcome card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  S.welcomeBack,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  client?.fullName ?? S.guest,
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                                if (client?.branchName != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        client!.branchName!,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Status alerts
                        if (_subscription != null) ...[
                          if (_subscription!.isExpiringSoon)
                            _buildAlertCard(
                              context,
                              icon: Icons.warning_amber,
                              color: Colors.orange,
                              title: S.subExpiringSoon,
                              message:
                                  S.subExpiresInDays(_subscription!.daysRemaining),
                            ),
                          if (_subscription!.isExpired)
                            _buildAlertCard(
                              context,
                              icon: Icons.error,
                              color: Colors.red,
                              title: S.subExpired,
                              message: S.pleaseRenew,
                            ),
                          if (_subscription!.isFrozen)
                            _buildAlertCard(
                              context,
                              icon: Icons.ac_unit,
                              color: Colors.blue,
                              title: S.subFrozen,
                              message: S.subCurrentlyFrozen,
                            ),
                          if (_subscription!.isRunningLow)
                            _buildAlertCard(
                              context,
                              icon: Icons.warning_amber,
                              color: Colors.orange,
                              title: _subscription!.displayMetric == 'coins'
                                  ? S.lowCoinBalance
                                  : S.fewSessionsLeft,
                              message: _subscription!.displayMetric == 'coins'
                                  ? S.onlyCoinsRemaining(_subscription!.remainingCoins)
                                  : S.onlySessionsRemaining(_subscription!.displayValue),
                            ),
                          const SizedBox(height: 16),

                          // Subscription info card
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        S.subscription,
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                      _buildStatusBadge(_subscription!.status),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow(
                                    context,
                                    icon: Icons.card_membership,
                                    label: S.type,
                                    value: _getTypeLabel(_subscription!.subscriptionType, _subscription!.displayMetric),
                                  ),
                                  if (_subscription!.displayMetric == 'time' &&
                                      _subscription!.expiryDate != null) ...[
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      context,
                                      icon: Icons.calendar_today,
                                      label: S.expiresLabel,
                                      value:
                                          '${_subscription!.expiryDate!.day.toString().padLeft(2,'0')}/${_subscription!.expiryDate!.month.toString().padLeft(2,'0')}/${_subscription!.expiryDate!.year}',
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  _buildInfoRow(
                                    context,
                                    icon: _getDisplayIcon(_subscription!.displayMetric),
                                    label: _getDisplayLabelText(_subscription!.displayMetric),
                                    value: _subscription!.displayLabel,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Quick actions
                        Text(
                          S.quickActions,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionCard(
                                context,
                                icon: Icons.qr_code_2,
                                label: S.myQRCode,
                                onTap: () => context.go('/client/qr'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionCard(
                                context,
                                icon: Icons.card_membership,
                                label: S.subscription,
                                onTap: () => context.go('/client/subscription'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildActionCard(
                          context,
                          icon: Icons.history,
                          label: S.entryHistory,
                          onTap: () => context.go('/client/history'),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildAlertCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        break;
      case 'frozen':
        color = Colors.blue;
        break;
      case 'stopped':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    String statusText;
    switch (status.toLowerCase()) {
      case 'active':
        statusText = S.active;
        break;
      case 'frozen':
        statusText = S.subFrozen;
        break;
      case 'stopped':
        statusText = S.stopSubscription;
        break;
      default:
        statusText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }

  String _getTypeLabel(String rawType, String? metric) {
    switch (metric) {
      case 'coins':
        return S.coinBased;
      case 'time':
        return S.timeBased;
      case 'sessions':
        return S.sessionBased;
      case 'training':
        return S.personalTrainingType;
      default:
        return rawType
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');
    }
  }

  IconData _getDisplayIcon(String? metric) {
    switch (metric) {
      case 'coins':
        return Icons.monetization_on;
      case 'time':
        return Icons.access_time;
      case 'sessions':
      case 'training':
        return Icons.fitness_center;
      default:
        return Icons.info;
    }
  }

  String _getDisplayLabelText(String? metric) {
    switch (metric) {
      case 'coins':
        return S.remainingLabel;
      case 'time':
        return S.timeLeft;
      case 'sessions':
        return S.sessionsLabel;
      case 'training':
        return S.training;
      default:
        return S.remainingLabel;
    }
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                icon,
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
