import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../shared/models/customer_model.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/localization/app_strings.dart';

class HealthReportScreen extends StatelessWidget {
  final CustomerModel customer;

  const HealthReportScreen({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.healthReport),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareReport(context),
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printReport(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      child: Text(
                        customer.fullName[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      customer.fullName,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          S.yearsOld(customer.age?.toString() ?? S.na),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          customer.gender == 'male' ? Icons.male : Icons.female,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          customer.gender?.toUpperCase() ?? S.na,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // QR Code Section
            if (customer.id != null) ...[
              Text(
                S.customerQRCode,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300, width: 2),
                        ),
                        child: QrImageView(
                          data: 'CUSTOMER-${customer.id}',
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                          gapless: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: SelectableText(
                                'ID: ${customer.id}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  color: Colors.black, // Force black color for visibility
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: 'CUSTOMER-${customer.id}'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(S.qrCopied),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              tooltip: S.copyQRCode,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        S.scanQRForIdentification,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Physical Measurements
            Text(
              'Physical Measurements',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMeasurementCard(
                    context,
                    icon: Icons.monitor_weight,
                    label: S.weight,
                    value: '${customer.weight?.toStringAsFixed(1) ?? "N/A"} kg',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMeasurementCard(
                    context,
                    icon: Icons.height,
                    label: S.height,
                    value: '${customer.height?.toStringAsFixed(2) ?? "N/A"} m',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // BMI Section
            Text(
              'Body Mass Index (BMI)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.bmiScore,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              customer.bmi?.toStringAsFixed(1) ?? 'N/A',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _getBMIColor(customer.bmiCategory),
                                  ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getBMIColor(customer.bmiCategory).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            customer.bmiCategory ?? S.unknown,
                            style: TextStyle(
                              color: _getBMIColor(customer.bmiCategory),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildBMIChart(customer.bmi),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Metabolic Information
            Text(
              'Metabolic Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildInfoRow(
                      context,
                      icon: Icons.local_fire_department,
                      label: S.basalMetabolicRate,
                      value: '${customer.bmr?.toStringAsFixed(0) ?? "N/A"} kcal/day',
                      subtitle: S.caloriesBurnedAtRest,
                    ),
                    const Divider(height: 32),
                    _buildInfoRow(
                      context,
                      icon: Icons.restaurant,
                      label: S.dailyCalorieNeeds,
                      value: '${customer.dailyCalories?.toStringAsFixed(0) ?? "N/A"} kcal/day',
                      subtitle: S.forModerateActivity,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recommendations
            Text(
              'Recommendations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.blue.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          S.healthTips,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._getRecommendations(customer.bmiCategory).map(
                      (tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(child: Text(tip)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Footer
            Center(
              child: Text(
                S.generatedOn(DateHelper.formatDate(DateTime.now())),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ],
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildBMIChart(double? bmi) {
    final ranges = [
      {'label': S.underweight, 'color': Colors.blue, 'max': 18.5},
      {'label': S.normal, 'color': Colors.green, 'max': 24.9},
      {'label': S.overweight, 'color': Colors.orange, 'max': 29.9},
      {'label': S.obese, 'color': Colors.red, 'max': 40.0},
    ];

    return Column(
      children: [
        Row(
          children: ranges.map((range) {
            return Expanded(
              child: Container(
                height: 8,
                color: range['color'] as Color,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ranges.map((range) {
            return Text(
              range['label'] as String,
              style: const TextStyle(fontSize: 10),
            );
          }).toList(),
        ),
        if (bmi != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment((bmi - 20) / 15, 0),
            child: Icon(Icons.arrow_drop_up, size: 32, color: _getBMIColor(null)),
          ),
        ],
      ],
    );
  }

  Color _getBMIColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'underweight':
        return Colors.blue;
      case 'normal':
        return Colors.green;
      case 'overweight':
        return Colors.orange;
      case 'obese':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<String> _getRecommendations(String? category) {
    switch (category?.toLowerCase()) {
      case 'underweight':
        return [
          S.tipIncreaseCaloric,
          S.tipStrengthTraining,
          S.tipConsultNutritionist,
        ];
      case 'normal':
        return [
          S.tipMaintainHealthy,
          S.tipContinueExercise,
          S.tipBalancedDiet,
        ];
      case 'overweight':
        return [
          S.tipCalorieDeficit,
          S.tipIncreaseCardio,
          S.tipPortionControl,
        ];
      case 'obese':
        return [
          S.tipConsultHealthcare,
          S.tipLowImpact,
          S.tipWorkWithDietitian,
        ];
      default:
        return [
          S.tipMaintainBalanced,
          S.tipExerciseRegularly,
          S.tipStayHydrated,
        ];
    }
  }

  void _shareReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(S.shareWhatsAppSoon),
      ),
    );
  }

  void _printReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(S.printSoon),
      ),
    );
  }
}
