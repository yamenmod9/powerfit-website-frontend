import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/app_strings.dart';
import '../core/api/client_api_service.dart';
import '../models/subscription_model.dart';
import '../../shared/widgets/skeleton_loader.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
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
      final apiService = context.read<ClientApiService>();
      final response = await apiService.getProfile();

      // ── DEBUG ──────────────────────────────────────────────────────
      // ignore: avoid_print
      print('🌐 [PlanScreen] Raw /client/me response: $response');
      if (response['data'] != null) {
        final sub = response['data']['active_subscription'];
        // ignore: avoid_print
        print('🌐 [PlanScreen] active_subscription raw: $sub');
      }
      // ──────────────────────────────────────────────────────────────

      if (response['status'] == 'success' || response['success'] == true) {
        final profileData = response['data'];

        // Check if there's active subscription data
        if (profileData['active_subscription'] != null) {
          setState(() {
            _subscription = SubscriptionModel.fromJson(profileData['active_subscription']);
          });
        } else {
          setState(() {
            _error = S.noActiveSubFound;
          });
        }
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load subscription';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/client/home');
            }
          },
        ),
        title: const Text(S.subscriptionDetails),
      ),
      body: _isLoading
          ? const DashboardSkeleton()
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSubscription,
                        child: const Text(S.retry),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSubscription,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: _subscription != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Status card
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    children: [
                                      Icon(
                                        _subscription!.isActive
                                            ? Icons.check_circle
                                            : _subscription!.isFrozen
                                                ? Icons.ac_unit
                                                : Icons.cancel,
                                        size: 64,
                                        color: _subscription!.isActive
                                            ? Colors.green
                                            : _subscription!.isFrozen
                                                ? Colors.blue
                                                : Colors.red,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _subscription!.status.toUpperCase(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              color: _subscription!.isActive
                                                  ? Colors.green
                                                  : _subscription!.isFrozen
                                                      ? Colors.blue
                                                      : Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      if (_subscription!.isExpiringSoon) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          S.expiresInDays(_subscription!.daysRemaining),
                                          style: const TextStyle(color: Colors.orange),
                                        ),
                                      ],
                                      if (_subscription!.isRunningLow) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          _subscription!.displayMetric == 'coins'
                                              ? S.onlyCoinsRemaining(_subscription!.remainingCoins)
                                              : S.onlySessionsRemaining(_subscription!.displayValue),
                                          style: const TextStyle(color: Colors.orange),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Subscription info
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        S.subscriptionInformation,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                      const SizedBox(height: 16),

                                      // Plan / Service name
                                      if (_subscription!.serviceName != null) ...[
                                        _buildInfoRow(
                                          context,
                                          icon: Icons.fitness_center,
                                          label: S.planLabel,
                                          value: _subscription!.serviceName!,
                                        ),
                                        const Divider(height: 24),
                                      ],

                                      // Type
                                      _buildInfoRow(
                                        context,
                                        icon: Icons.card_membership,
                                        label: S.type,
                                        value: _getSubscriptionTypeLabel(
                                            _subscription!.subscriptionType,
                                            _subscription!.displayMetric),
                                      ),
                                      const Divider(height: 24),

                                      // Start date
                                      _buildInfoRow(
                                        context,
                                        icon: Icons.calendar_today,
                                        label: S.startDate,
                                        value: _formatDate(_subscription!.startDate),
                                      ),

                                      // Expiry date — only for time-based
                                      if (_subscription!.displayMetric == 'time' &&
                                          _subscription!.expiryDate != null) ...[
                                        const Divider(height: 24),
                                        _buildInfoRow(
                                          context,
                                          icon: Icons.event,
                                          label: S.expiryDate,
                                          value: _formatDate(_subscription!.expiryDate!),
                                          valueColor: _subscription!.isExpiringSoon
                                              ? Colors.orange
                                              : _subscription!.isExpired
                                                  ? Colors.red
                                                  : null,
                                        ),
                                      ],

                                      const Divider(height: 24),

                                      // Main metric row
                                      _buildInfoRow(
                                        context,
                                        icon: _getDisplayIcon(_subscription!.displayMetric),
                                        label: _getDisplayLabel(_subscription!.displayMetric),
                                        value: _subscription!.displayLabel,
                                        valueColor: _subscription!.isRunningLow
                                            ? Colors.orange
                                            : _subscription!.isExpiringSoon
                                                ? Colors.orange
                                                : null,
                                      ),

                                      // Progress bar for coins
                                      if (_subscription!.displayMetric == 'coins' &&
                                          _subscription!.totalCoins != null &&
                                          _subscription!.totalCoins! > 0) ...[
                                        const SizedBox(height: 12),
                                        _buildProgressBar(
                                          context,
                                          current: _subscription!.remainingCoins,
                                          total: _subscription!.totalCoins!,
                                          color: _subscription!.isRunningLow
                                              ? Colors.orange
                                              : Theme.of(context).primaryColor,
                                        ),
                                      ],

                                      // Progress bar for sessions/training
                                      if ((_subscription!.displayMetric == 'sessions' ||
                                              _subscription!.displayMetric == 'training') &&
                                          _subscription!.totalSessions != null &&
                                          _subscription!.totalSessions! > 0) ...[
                                        const SizedBox(height: 12),
                                        _buildProgressBar(
                                          context,
                                          current: _subscription!.remainingSessions ?? 0,
                                          total: _subscription!.totalSessions!,
                                          color: _subscription!.isRunningLow
                                              ? Colors.orange
                                              : Colors.green,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Allowed services
                              if (_subscription!.allowedServices.isNotEmpty) ...[
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.fitness_center,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              S.allowedServices,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: _subscription!
                                              .allowedServices
                                              .map(
                                                (service) => Chip(
                                                  label: Text(service),
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .primaryColor
                                                          .withValues(alpha: 0.2),
                                                  side: BorderSide(
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Freeze history
                              if (_subscription!.freezeHistory.isNotEmpty) ...[
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.ac_unit,
                                              color: Colors.blue,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              S.freezeHistory,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        ..._subscription!.freezeHistory
                                            .map((freeze) => Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 12),
                                                  child: _buildFreezeItem(
                                                      context, freeze),
                                                )),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          )
                        : const Center(
                            child: Text(S.noSubscriptionData),
                          ),
                  ),
                ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
        ),
      ],
    );
  }

  Widget _buildFreezeItem(BuildContext context, FreezeHistory freeze) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                S.frozenDate('${freeze.freezeDate.day}/${freeze.freezeDate.month}/${freeze.freezeDate.year}'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          if (freeze.unfreezeDate != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.event, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  S.unfrozenDate('${freeze.unfreezeDate!.day}/${freeze.unfreezeDate!.month}/${freeze.unfreezeDate!.year}'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
          if (freeze.reason.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              S.reason(freeze.reason),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getSubscriptionTypeLabel(String rawType, String? metric) {
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
        // Fall back to prettifying the raw type
        return rawType
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');
    }
  }

  Widget _buildProgressBar(
    BuildContext context, {
    required int current,
    required int total,
    required Color color,
  }) {
    final fraction = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          S.progressLabel(current, total),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
        ),
      ],
    );
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

  String _getDisplayLabel(String? metric) {
    switch (metric) {
      case 'coins':
        return S.remainingCoinsLabel;
      case 'time':
        return S.timeRemainingLabel;
      case 'sessions':
        return S.sessionsRemainingLabel;
      case 'training':
        return S.trainingSessionsLabel;
      default:
        return S.remainingLabel;
    }
  }
}

