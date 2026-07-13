import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/localization/app_strings.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  String? _lastScannedCode;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;

    if (_isProcessing) {
      return;
    }

    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;

      if (code != null && code != _lastScannedCode && code.isNotEmpty) {
        _lastScannedCode = code;
        _isProcessing = true;

        try {
          await cameraController.stop();
        } catch (e) {
          debugPrint('⚠️ Could not stop camera: $e');
        }

        await _processQRCode(code);

        await Future.delayed(const Duration(seconds: 3));
        _isProcessing = false;
        _lastScannedCode = null;

        if (mounted) {
          try {
            await cameraController.start();
          } catch (e) {
            debugPrint('⚠️ Could not restart camera: $e');
          }
        }

        break;
      }
    }
  }

  Future<void> _processQRCode(String qrCode) async {
    try {
      String customerId = qrCode.trim();

      if (customerId.contains('customer_id:')) {
        customerId = customerId.split('customer_id:').last.trim();
      } else if (customerId.contains('GYM-')) {
        customerId = customerId.split('-').last.trim();
      } else if (customerId.contains('CUST-')) {
        customerId = customerId.split('-').last.trim();
      } else if (customerId.contains(':')) {
        customerId = customerId.split(':').last.trim();
      }

      customerId = customerId.replaceAll(RegExp(r'[^0-9]'), '');

      if (customerId.isEmpty) {
        _showError(S.invalidQRFormat);
        return;
      }

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(S.loadingCustomer),
                ],
              ),
            ),
          ),
        ),
      );

      final apiService = context.read<ApiService>();
      final response = await apiService.get(
        ApiEndpoints.customerById(int.parse(customerId)),
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      if (response.statusCode == 200 && response.data != null) {
        Map<String, dynamic> customer;

        if (response.data is Map) {
          customer = response.data['customer'] ??
              response.data['data'] ??
              response.data;
        } else {
          _showError(S.invalidResponseFormat);
          return;
        }

        if (customer['id'] == null && customer['customer_id'] == null) {
          _showError(S.customerDataMissingId);
          return;
        }

        await _showCheckInDialog(customer);
      } else {
        _showError(S.customerNotFound(int.parse(customerId)));
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showError('${S.invalidQRFormat}: $e');
      }
    }
  }

  Future<void> _showCheckInDialog(Map<String, dynamic> customer) async {
    final apiService = context.read<ApiService>();
    final customerId = customer['id'] ?? customer['customer_id'];
    final name = customer['full_name'] ?? customer['name'] ?? S.unknown;

    Map<String, dynamic>? activeSubscription;
    try {
      final subsResponse = await apiService.get(
        ApiEndpoints.subscriptions,
        queryParameters: {
          'customer_id': customerId,
          'status': 'active',
        },
      );

      if (subsResponse.statusCode == 200 && subsResponse.data != null) {
        var subs = [];
        if (subsResponse.data is List) {
          subs = subsResponse.data;
        } else if (subsResponse.data['data'] != null) {
          subs = subsResponse.data['data'] is Map
              ? (subsResponse.data['data']['items'] ?? [])
              : subsResponse.data['data'];
        } else if (subsResponse.data['items'] != null) {
          subs = subsResponse.data['items'];
        }

        if (subs.isNotEmpty) {
          activeSubscription = subs.first;
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching subscription: $e');
    }

    if (!mounted) return;

    final confirmed = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.checkInTitle(name)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.customerIdLabel(customerId)),
            const SizedBox(height: 8),
            if (activeSubscription != null) ...[
              const Divider(),
              Text(
                S.activeSubscription,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text(S.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'confirm'),
            child: const Text(S.confirm),
          ),
        ],
      ),
    );

    if (confirmed == 'confirm' && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in successful')),
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Scanner')),
      body: MobileScanner(
        controller: cameraController,
        onDetect: _handleBarcode,
      ),
    );
  }
}