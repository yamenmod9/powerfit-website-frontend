import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/reception_provider.dart';
import '../../../core/localization/app_strings.dart';

class ActivateSubscriptionDialog extends StatefulWidget {
  const ActivateSubscriptionDialog({super.key});

  @override
  State<ActivateSubscriptionDialog> createState() => _ActivateSubscriptionDialogState();
}

class _ActivateSubscriptionDialogState extends State<ActivateSubscriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerIdController = TextEditingController();
  final _amountController = TextEditingController();

  String _paymentMethod = 'cash';
  String? _subscriptionType;
  String? _packageDuration; // For time-based packages
  String? _coinsAmount; // For coins packages
  String? _sessionsAmount; // For personal training packages
  bool _isLoading = false;

  // Subscription type options
  final List<Map<String, String>> _subscriptionTypes = [
    {
      'value': 'coins',
      'label': S.coinsPackage,
      'icon': '💰',
      'description': S.oneYearValidity,
    },
    {
      'value': 'time_based',
      'label': S.timeBasedPackage,
      'icon': '📅',
      'description': S.monthOptions,
    },
    {
      'value': 'personal_training',
      'label': S.personalTraining,
      'icon': '🏋️',
      'description': S.sessionsWithTrainer,
    },
  ];

  // Duration options for time-based packages
  final List<Map<String, String>> _timeDurations = [
    {'value': '1', 'label': S.month1},
    {'value': '3', 'label': S.months3},
    {'value': '6', 'label': S.months6},
    {'value': '9', 'label': S.months9},
    {'value': '12', 'label': S.months12},
  ];

  // Coins options
  final List<Map<String, String>> _coinsOptions = [
    {'value': '10', 'label': S.coins(10)},
    {'value': '20', 'label': S.coins(20)},
    {'value': '30', 'label': S.coins(30)},
    {'value': '50', 'label': S.coins(50)},
    {'value': '100', 'label': S.coins(100)},
  ];

  // Sessions options for personal training
  final List<Map<String, String>> _sessionsOptions = [
    {'value': '5', 'label': S.sessions(5)},
    {'value': '10', 'label': S.sessions(10)},
    {'value': '15', 'label': S.sessions(15)},
    {'value': '20', 'label': S.sessions(20)},
    {'value': '30', 'label': S.sessions(30)},
  ];

  @override
  void dispose() {
    _customerIdController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_subscriptionType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(S.pleaseSelectSubType)),
      );
      return;
    }

    // Validate type-specific fields
    if (_subscriptionType == 'coins' && _coinsAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(S.pleaseSelectCoins)),
      );
      return;
    }

    if (_subscriptionType == 'time_based' && _packageDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(S.pleaseSelectDuration)),
      );
      return;
    }

    if (_subscriptionType == 'personal_training' && _sessionsAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(S.pleaseSelectSessions)),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<ReceptionProvider>();

    // Prepare subscription details based on type
    // NOTE: backend expects 'training' not 'personal_training'
    final backendType = _subscriptionType == 'personal_training' ? 'training' : _subscriptionType;

    Map<String, dynamic> subscriptionDetails = {
      'subscription_type': backendType,
    };

    if (_subscriptionType == 'coins') {
      subscriptionDetails['coins'] = int.parse(_coinsAmount!);
      subscriptionDetails['coin_amount'] = int.parse(_coinsAmount!);
    } else if (_subscriptionType == 'time_based') {
      subscriptionDetails['duration_months'] = int.parse(_packageDuration!);
    } else if (_subscriptionType == 'personal_training') {
      subscriptionDetails['sessions'] = int.parse(_sessionsAmount!);
      subscriptionDetails['session_count'] = int.parse(_sessionsAmount!);
    }

    final result = await provider.activateSubscription(
      customerId: int.parse(_customerIdController.text),
      serviceId: 1, // Default service ID (automatic)
      amount: double.parse(_amountController.text),
      paymentMethod: _paymentMethod,
      subscriptionDetails: subscriptionDetails,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        // Reload provider data to update statistics
        await provider.refresh();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? S.subscriptionActivated),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Show detailed error dialog instead of just snackbar
        final errorMessage = result['message'] ?? S.activationFailed;
        final errorDetails = result['error_details'];

        // Check if it's a CORS error
        if (errorDetails != null && errorDetails['type'] == 'CORS') {
          _showCorsErrorDialog(context, errorMessage);
        } else {
          // Show regular error with details
          _showErrorDialog(context, errorMessage, errorDetails);
        }
      }
    }
  }

  void _showCorsErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text(S.corsErrorDetected),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.corsDescription,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                S.immediateSolution,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(S.closeThisApp),
              Text(S.runDebugBat),
              Text(S.selectOption1),
              Text(S.orOption2),
              const SizedBox(height: 16),
              Text(
                S.whyAndroid,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(S.noCorsRestrictions),
              Text(S.directBackendConnection),
              Text(S.allFeaturesWork),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.technicalDetails,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      S.corsExplanation,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.close),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('${S.runOnAndroid} - DEBUG_SUBSCRIPTION_ACTIVATION.bat'),
                  duration: Duration(seconds: 5),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.android),
            label: Text(S.runOnAndroid),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message, Map<String, dynamic>? details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text(S.activationFailed),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (details != null) ...[
                const SizedBox(height: 16),
                Text(
                  S.details,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    details.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.close),
          ),
          if (details?['type'] == 'auth')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Could trigger logout/re-login here
              },
              child: Text(S.loginAgain),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = screenHeight * 0.85 - keyboardHeight;
    final dialogWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.9;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: keyboardHeight > 0 ? 10 : 24,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: maxHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.card_membership,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      S.activateSubscription,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _customerIdController,
                        decoration: const InputDecoration(
                          labelText: S.customerIdRequired,
                          prefixIcon: Icon(Icons.person),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => v?.isEmpty ?? true ? S.required : null,
                      ),
                      const SizedBox(height: 12),

                      // Subscription Type Dropdown
                      DropdownButtonFormField<String>(
                        value: _subscriptionType,
                        decoration: InputDecoration(
                          labelText: S.subscriptionTypeRequired,
                          prefixIcon: const Icon(Icons.category),
                          helperText: S.chooseSubType,
                        ),
                        isExpanded: true,
                        items: _subscriptionTypes.map((type) {
                          return DropdownMenuItem(
                            value: type['value'],
                            child: Text('${type['icon']} ${type['label']}'),
                          );
                        }).toList(),
                        onChanged: (v) {
                          setState(() {
                            _subscriptionType = v;
                            _packageDuration = null;
                            _coinsAmount = null;
                            _sessionsAmount = null;
                          });
                        },
                        validator: (v) => v == null ? S.pleaseSelectSubType : null,
                      ),
                      const SizedBox(height: 12),

                      // Conditional fields based on subscription type
                      if (_subscriptionType == 'coins') ...[
                        DropdownButtonFormField<String>(
                          value: _coinsAmount,
                          decoration: InputDecoration(
                            labelText: S.coinsAmountRequired,
                            prefixIcon: const Icon(Icons.monetization_on),
                            helperText: S.validFor1Year,
                          ),
                          items: _coinsOptions.map((option) {
                            return DropdownMenuItem<String>(
                              value: option['value'],
                              child: Text(option['label']!),
                            );
                          }).toList(),
                          onChanged: (v) {
                            setState(() {
                              _coinsAmount = v;
                            });
                          },
                          validator: (v) => v == null ? S.pleaseSelectCoins : null,
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (_subscriptionType == 'time_based') ...[
                        DropdownButtonFormField<String>(
                          value: _packageDuration,
                          decoration: InputDecoration(
                            labelText: S.durationRequired,
                            prefixIcon: const Icon(Icons.calendar_month),
                            helperText: S.selectSubDuration,
                          ),
                          items: _timeDurations.map((duration) {
                            return DropdownMenuItem<String>(
                              value: duration['value'],
                              child: Text(duration['label']!),
                            );
                          }).toList(),
                          onChanged: (v) {
                            setState(() {
                              _packageDuration = v;
                            });
                          },
                          validator: (v) => v == null ? S.pleaseSelectDuration : null,
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (_subscriptionType == 'personal_training') ...[
                        DropdownButtonFormField<String>(
                          value: _sessionsAmount,
                          decoration: InputDecoration(
                            labelText: S.sessionsRequired,
                            prefixIcon: const Icon(Icons.fitness_center),
                            helperText: S.sessionsWithPersonalTrainer,
                          ),
                          items: _sessionsOptions.map((option) {
                            return DropdownMenuItem<String>(
                              value: option['value'],
                              child: Text(option['label']!),
                            );
                          }).toList(),
                          onChanged: (v) {
                            setState(() {
                              _sessionsAmount = v;
                            });
                          },
                          validator: (v) => v == null ? S.pleaseSelectSessions : null,
                        ),
                        const SizedBox(height: 12),
                      ],

                      TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: S.amountRequired,
                          prefixIcon: const Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => v?.isEmpty ?? true ? S.required : null,
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: _paymentMethod,
                        decoration: InputDecoration(
                          labelText: S.paymentMethodRequired,
                          prefixIcon: const Icon(Icons.payment),
                        ),
                        items: [
                          DropdownMenuItem(value: 'cash', child: Text(S.cash)),
                          DropdownMenuItem(value: 'card', child: Text(S.card)),
                          DropdownMenuItem(value: 'transfer', child: Text(S.transfer)),
                        ],
                        onChanged: (v) => setState(() => _paymentMethod = v!),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[800]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text(S.cancel),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading
                        ? const SmallLoadingIndicator()
                        : Text(S.activate),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
