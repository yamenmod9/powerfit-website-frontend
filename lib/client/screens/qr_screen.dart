import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../../core/localization/app_strings.dart';
import '../core/auth/client_auth_provider.dart';
import '../core/api/client_api_service.dart';
import '../core/theme/client_theme.dart';

/// QR check-in screen, styled to the PowerFit Member App design: a white QR
/// card glowing crimson on a dark radial ground, with the member's name,
/// status pill, live validity countdown, and refresh.
class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  String? _qrCode;
  DateTime? _expiresAt;
  Timer? _countdownTimer;
  int _secondsRemaining = 0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadQrCode();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadQrCode() async {
    final client = context.read<ClientAuthProvider>().currentClient;
    if (client != null && mounted) {
      setState(() {
        _qrCode = client.qrCode;
        _expiresAt = DateTime.now().add(const Duration(hours: 1));
        _startCountdown();
      });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _updateSecondsRemaining();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateSecondsRemaining();
    });
  }

  void _updateSecondsRemaining() {
    if (_expiresAt != null) {
      final remaining = _expiresAt!.difference(DateTime.now()).inSeconds;
      setState(() {
        _secondsRemaining = remaining > 0 ? remaining : 0;
      });
      if (_secondsRemaining == 0) {
        _countdownTimer?.cancel();
      }
    }
  }

  String _formatCountdown() {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _refreshQrCode() async {
    setState(() => _isRefreshing = true);
    try {
      final apiService = context.read<ClientApiService>();
      final response = await apiService.refreshQrCode();

      if (response['status'] == 'success') {
        setState(() {
          _qrCode = response['data']['qr_code'];
          _expiresAt = DateTime.parse(response['data']['expires_at']);
          _startCountdown();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.qrRefreshed),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.failedToRefresh(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = context.watch<ClientAuthProvider>().currentClient;
    final isExpired = _secondsRemaining == 0;

    String displayQrCode;
    if (_qrCode?.isNotEmpty == true) {
      displayQrCode = _qrCode!;
    } else if (client != null && client.qrCode.isNotEmpty) {
      displayQrCode = client.qrCode;
    } else {
      displayQrCode = 'customer_id:${client?.id ?? 0}';
    }
    if (!displayQrCode.startsWith('customer_id:') &&
        !displayQrCode.startsWith('GYM-') &&
        !displayQrCode.startsWith('CUST-')) {
      if (RegExp(r'^\d+$').hasMatch(displayQrCode)) {
        displayQrCode = 'customer_id:$displayQrCode';
      } else if (client?.id != null) {
        displayQrCode = 'customer_id:${client!.id}';
      }
    }

    final canScan = client != null && !isExpired;

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.35),
          radius: 1.1,
          colors: [Color(0xFF2A0A12), ClientTheme.darkGrey],
          stops: [0.0, 0.7],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header (back button only when this screen was pushed as a route).
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  if (context.canPop())
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    )
                  else
                    const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      S.entryCode,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    icon: _isRefreshing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.refresh, color: Colors.white),
                    tooltip: S.refreshQRCode,
                    onPressed: _isRefreshing ? null : _refreshQrCode,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // White QR card with crimson glow.
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: ClientTheme.primaryRed.withValues(alpha: 0.3),
                            blurRadius: 40,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: displayQrCode,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                        // ignore: deprecated_member_use
                        foregroundColor: Colors.black,
                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                        gapless: true,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      client?.fullName ?? S.guest,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        displayQrCode,
                        style: const TextStyle(
                            color: ClientTheme.textGrey,
                            fontFamily: 'monospace',
                            fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _statusPill(client?.subscriptionStatus ?? 'inactive',
                        client?.branchName),
                    const SizedBox(height: 12),
                    _countdownChip(isExpired),
                    const SizedBox(height: 20),
                    Text(
                      canScan ? S.pointCodeAtScanner : S.qrCodeExpired,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: ClientTheme.subtleGrey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String status, String? branch) {
    Color dot;
    String label;
    switch (status.toLowerCase()) {
      case 'active':
        dot = const Color(0xFF10B981);
        label = S.activeSubscriptionStatus;
        break;
      case 'frozen':
        dot = const Color(0xFF3B82F6);
        label = S.subscriptionFrozenStatus;
        break;
      case 'stopped':
        dot = ClientTheme.primaryRed;
        label = S.subscriptionStoppedStatus;
        break;
      default:
        dot = const Color(0xFF6A6A6A);
        label = S.inactiveStatus;
    }
    final text = branch != null ? '$branch · $label' : label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: ClientTheme.cardGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(text,
              style: const TextStyle(color: ClientTheme.textGrey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _countdownChip(bool isExpired) {
    if (_expiresAt == null) return const SizedBox.shrink();
    final color = isExpired ? ClientTheme.primaryRed : Colors.white70;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(isExpired ? Icons.error_outline : Icons.timer_outlined,
            size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          isExpired ? S.qrCodeExpired : S.expiresIn(_formatCountdown()),
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
