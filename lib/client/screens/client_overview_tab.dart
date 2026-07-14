import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/app_strings.dart';
import '../core/auth/client_auth_provider.dart';
import '../core/api/client_api_service.dart';
import '../core/theme/client_theme.dart';
import '../models/subscription_model.dart';

/// Home tab of the member app, styled to the PowerFit Member App design:
/// greeting header, a crimson subscription card with the remaining balance
/// and status, a quick check-in shortcut, and the subscription details.
class ClientOverviewTab extends StatefulWidget {
  /// Switches the shell to the Check-in (QR) tab.
  final VoidCallback? onGoToCheckIn;

  const ClientOverviewTab({super.key, this.onGoToCheckIn});

  @override
  State<ClientOverviewTab> createState() => _ClientOverviewTabState();
}

class _ClientOverviewTabState extends State<ClientOverviewTab> {
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

      bool isSuccess = false;
      if (response.containsKey('success')) {
        isSuccess = response['success'] == true;
      } else if (response.containsKey('status')) {
        isSuccess = response['status'] == 'success';
      }

      if (isSuccess && response['data'] != null) {
        final data = response['data'];
        if (data['active_subscription'] != null) {
          setState(() {
            _subscription = SubscriptionModel.fromJson(data['active_subscription']);
          });
        } else if (data['subscription'] != null) {
          setState(() {
            _subscription = SubscriptionModel.fromJson(data['subscription']);
          });
        } else {
          setState(() => _error = S.noActiveSubFound);
        }
      } else {
        setState(() => _error = response['message'] ?? 'Failed to load profile');
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains('404')) {
        errorMsg = S.subEndpointNotAvailable;
      }
      setState(() => _error = errorMsg);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = context.watch<ClientAuthProvider>().currentClient;

    return Container(
      color: ClientTheme.darkGrey,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: ClientTheme.primaryRed,
          onRefresh: _loadSubscription,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: ClientTheme.primaryRed))
              : _error != null
                  ? _buildError()
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                      children: [
                        _buildHeader(client?.fullName),
                        const SizedBox(height: 20),
                        if (_subscription != null) ...[
                          _buildSubscriptionCard(_subscription!),
                          const SizedBox(height: 16),
                        ],
                        _buildCheckInButton(),
                        const SizedBox(height: 16),
                        if (_subscription != null) ...[
                          ..._buildAlerts(_subscription!),
                          _buildDetailsCard(_subscription!),
                        ],
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 120, horizontal: 24),
      children: [
        const Icon(Icons.error_outline, size: 64, color: ClientTheme.primaryRed),
        const SizedBox(height: 16),
        Text(_error!, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton(
            onPressed: _loadSubscription,
            child: const Text(S.retry),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String? name) {
    final initial = (name != null && name.isNotEmpty)
        ? name.characters.first.toUpperCase()
        : 'U';
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: ClientTheme.primaryRed,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.welcomeBack,
                style: const TextStyle(color: ClientTheme.subtleGrey, fontSize: 12),
              ),
              Text(
                name ?? S.guest,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ],
          ),
        ),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: ClientTheme.cardGrey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.notifications_none_rounded,
              size: 20, color: Colors.white70),
        ),
      ],
    );
  }

  // ── Subscription hero card ─────────────────────────────────────────────
  Widget _buildSubscriptionCard(SubscriptionModel sub) {
    final chip = _statusChip(sub.status);
    final big = _bigValue(sub);
    final fraction = _progressFraction(sub);

    return GestureDetector(
      onTap: () => context.pushNamed('subscription'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ClientTheme.primaryRed, Color(0xFF7F0F22)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ClientTheme.primaryRed.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    sub.serviceName ?? S.subscription,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: chip.$1,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    chip.$2,
                    style: TextStyle(
                        color: chip.$3, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              textBaseline: TextBaseline.alphabetic,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              children: [
                Text(
                  '${big.$1}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1),
                ),
                const SizedBox(width: 6),
                Text(
                  big.$2,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              sub.displayMetric == 'time' ? S.untilRenewal : S.remainingLabel,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
            ),
            if (fraction != null) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 6,
                  backgroundColor: Colors.black.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInButton() {
    return Material(
      color: ClientTheme.cardGrey,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onGoToCheckIn,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientTheme.primaryRed.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ClientTheme.primaryRed.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.qr_code_2_rounded,
                    color: ClientTheme.primaryRed),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.quickCheckIn,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      S.showQrAtDoor,
                      style: const TextStyle(
                          color: ClientTheme.subtleGrey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAlerts(SubscriptionModel sub) {
    final alerts = <Widget>[];
    if (sub.isExpiringSoon) {
      alerts.add(_alertCard(Icons.warning_amber_rounded, ClientTheme.primaryRed,
          S.subExpiringSoon, S.subExpiresInDays(sub.daysRemaining)));
    }
    if (sub.isExpired) {
      alerts.add(_alertCard(Icons.error_outline, ClientTheme.primaryRed,
          S.subExpired, S.pleaseRenew));
    }
    if (sub.isFrozen) {
      alerts.add(_alertCard(Icons.ac_unit, const Color(0xFF3B82F6),
          S.subFrozen, S.subCurrentlyFrozen));
    }
    if (sub.isRunningLow) {
      alerts.add(_alertCard(
        Icons.warning_amber_rounded,
        const Color(0xFFF59E0B),
        sub.displayMetric == 'coins' ? S.lowCoinBalance : S.fewSessionsLeft,
        sub.displayMetric == 'coins'
            ? S.onlyCoinsRemaining(sub.remainingCoins)
            : S.onlySessionsRemaining(sub.displayValue),
      ));
    }
    return alerts;
  }

  Widget _alertCard(IconData icon, Color color, String title, String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(message,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(SubscriptionModel sub) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClientTheme.cardGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(S.subscriptionDetails,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
              GestureDetector(
                onTap: () => context.pushNamed('subscription'),
                child: const Text(S.manageSubscription,
                    style: TextStyle(
                        color: ClientTheme.primaryRed,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _detailRow(Icons.card_membership, S.type, _typeLabel(sub)),
          if (sub.displayMetric == 'time' && sub.expiryDate != null) ...[
            const Divider(color: Colors.white10, height: 22),
            _detailRow(
              Icons.calendar_today,
              S.expiresLabel,
              '${sub.expiryDate!.day.toString().padLeft(2, '0')}/${sub.expiryDate!.month.toString().padLeft(2, '0')}/${sub.expiryDate!.year}',
            ),
          ],
          const Divider(color: Colors.white10, height: 22),
          _detailRow(_metricIcon(sub.displayMetric), S.remainingLabel,
              sub.displayLabel),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: ClientTheme.primaryRed),
        const SizedBox(width: 12),
        Text('$label: ',
            style: const TextStyle(color: ClientTheme.textGrey, fontSize: 14)),
        Expanded(
          child: Text(value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  /// (background, text, textColor) for the status chip.
  (Color, String, Color) _statusChip(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return (const Color(0xFF10B981), S.active, const Color(0xFF04231A));
      case 'frozen':
        return (const Color(0xFF3B82F6), S.subFrozen, Colors.white);
      case 'stopped':
        return (ClientTheme.primaryRed, S.stopSubscription, Colors.white);
      default:
        return (const Color(0xFF6A6A6A), status, Colors.white);
    }
  }

  /// (number, unit) for the hero display.
  (int, String) _bigValue(SubscriptionModel sub) {
    switch (sub.displayMetric) {
      case 'coins':
        return (sub.remainingCoins, S.coinUnit);
      case 'sessions':
      case 'training':
        return (sub.displayValue, S.sessionUnit);
      case 'time':
      default:
        return (sub.daysRemaining, S.dayUnit);
    }
  }

  double? _progressFraction(SubscriptionModel sub) {
    if (sub.displayMetric == 'coins' &&
        sub.totalCoins != null &&
        sub.totalCoins! > 0) {
      return (sub.remainingCoins / sub.totalCoins!).clamp(0.0, 1.0);
    }
    if ((sub.displayMetric == 'sessions' || sub.displayMetric == 'training') &&
        sub.totalSessions != null &&
        sub.totalSessions! > 0) {
      return (sub.displayValue / sub.totalSessions!).clamp(0.0, 1.0);
    }
    if (sub.displayMetric == 'time' && sub.daysRemaining > 0) {
      // No total window from the API; show progress relative to a 30-day month.
      return (sub.daysRemaining / 30).clamp(0.0, 1.0);
    }
    return null;
  }

  String _typeLabel(SubscriptionModel sub) {
    switch (sub.displayMetric) {
      case 'coins':
        return S.coinBased;
      case 'time':
        return S.timeBased;
      case 'sessions':
        return S.sessionBased;
      case 'training':
        return S.personalTrainingType;
      default:
        return sub.subscriptionType;
    }
  }

  IconData _metricIcon(String? metric) {
    switch (metric) {
      case 'coins':
        return Icons.monetization_on;
      case 'time':
        return Icons.access_time;
      case 'sessions':
      case 'training':
        return Icons.fitness_center;
      default:
        return Icons.info_outline;
    }
  }
}
