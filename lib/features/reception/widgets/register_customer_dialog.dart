import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../core/providers/gym_branding_provider.dart';
import '../providers/reception_provider.dart';
import '../../../core/localization/app_strings.dart';

class RegisterCustomerDialog extends StatefulWidget {
  const RegisterCustomerDialog({super.key});

  @override
  State<RegisterCustomerDialog> createState() => _RegisterCustomerDialogState();
}

class _RegisterCustomerDialogState extends State<RegisterCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  String _gender = 'male';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  /// Build the customer email using the gym's domain.
  /// If the user typed just a name (no @), append @gymname.com.
  /// If they typed a full email, use it as-is.
  /// If empty, return null.
  String? _buildEmail() {
    final text = _emailController.text.trim();
    if (text.isEmpty) return null;
    if (text.contains('@')) return text;

    // Auto-append gym domain
    final branding = context.read<GymBrandingProvider>();
    return '$text@${branding.emailDomain}';
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<ReceptionProvider>();

      // Height is entered in cm by the user — pass it as-is to calculateHealthMetrics
      // (HealthHelper.calculateBMI/BMR internally convert cm → meters)
      final heightCm = double.parse(_heightController.text);

      debugPrint('=== REGISTRATION DEBUG ===');
      debugPrint('Name: ${_nameController.text}');
      debugPrint('Age: ${_ageController.text}');
      debugPrint('Weight: ${_weightController.text}');
      debugPrint('Height (cm): $heightCm');
      debugPrint('Gender: $_gender');
      debugPrint('Phone: ${_phoneController.text}');
      debugPrint('Email: ${_emailController.text}');
      debugPrint('Branch ID: ${provider.branchId}');

      // Always use the receptionist's own branch_id - can't register for other branches
      final customer = provider.calculateHealthMetrics(
        fullName: _nameController.text.trim(),
        weight: double.parse(_weightController.text),
        height: heightCm,
        age: int.parse(_ageController.text),
        gender: _gender,
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _buildEmail(),
        qrCode: null, // QR code will be generated from customer ID after registration
      );

      debugPrint('Customer Data: ${customer.toJson()}');
      debugPrint('Registering for Branch ID: ${provider.branchId}');
      debugPrint('========================');

      final result = await provider.registerCustomer(customer);

      debugPrint('Registration Result: $result');
      debugPrint('========================');

      if (mounted) {
        setState(() => _isLoading = false);

        if (result['success'] == true) {
          // Show success message with customer info
          final customerId = result['data']?['customer']?['id'] ?? result['data']?['id'];

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result['message'] ?? S.customerRegistered),
                  if (customerId != null)
                    Text(
                      S.customerIdCreated(customerId),
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        } else {
          // Show detailed error message
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(S.registrationFailed),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result['message'] ?? S.failedToRegister),
                    if (result['error'] != null) ...[
                      const SizedBox(height: 12),
                      Text(S.details, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        result['error'].toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(S.ok),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(S.error),
            content: Text('${S.unexpectedError}:\n${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(S.ok),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = screenHeight * 0.85 - keyboardHeight; // Adjust for keyboard
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_add,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      S.registerNewCustomer,
                      style: TextStyle(
                        fontSize: 16,
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: S.fullNameRequired,
                          prefixIcon: Icon(Icons.person, size: 20),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        validator: (v) => v?.isEmpty ?? true ? S.required : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: S.phone,
                          prefixIcon: Icon(Icons.phone, size: 20),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),

                      Builder(
                        builder: (context) {
                          final branding = context.watch<GymBrandingProvider>();
                          final domain = branding.emailDomain;
                          return TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: S.email,
                              hintText: 'name@$domain',
                              prefixIcon: const Icon(Icons.email, size: 20),
                              suffixText: '@$domain',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (value) {
                              // Auto-append gym domain if user types just a username
                              if (value.isNotEmpty && !value.contains('@')) {
                                // Don't modify while typing — hint shows the domain
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: const InputDecoration(
                          labelText: S.genderRequired,
                          prefixIcon: Icon(Icons.wc, size: 18),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text(S.male)),
                          DropdownMenuItem(value: 'female', child: Text(S.female)),
                        ],
                        onChanged: (v) => setState(() => _gender = v!),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _ageController,
                        decoration: const InputDecoration(
                          labelText: S.ageRequired,
                          prefixIcon: Icon(Icons.cake, size: 20),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => v?.isEmpty ?? true ? S.required : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _weightController,
                        decoration: InputDecoration(
                          labelText: S.weightRequired,
                          prefixIcon: Icon(Icons.monitor_weight, size: 20),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => v?.isEmpty ?? true ? S.required : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _heightController,
                        decoration: InputDecoration(
                          labelText: S.heightRequired,
                          prefixIcon: Icon(Icons.height, size: 20),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.qr_code,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                S.qrAndHealthAutoGenerated,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontSize: 12,
                                    ),
                              ),
                            ),
                          ],
                        ),
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
                        : Text(S.register),
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
