import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/api/api_service.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/gym_branding_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../shared/models/gym_model.dart';
import '../../../shared/widgets/loading_indicator.dart';

/// Four-step wizard shown when a gym owner logs in for the first time.
///
/// Step 1 — Gym Name
/// Step 2 — Logo Upload
/// Step 3 — Brand Colors (primary + secondary)
/// Step 4 — Preferred Language
///
/// On completion the branding provider is updated and the owner is sent
/// to their normal dashboard.
class GymSetupWizard extends StatefulWidget {
  const GymSetupWizard({super.key});

  @override
  State<GymSetupWizard> createState() => _GymSetupWizardState();
}

class _GymSetupWizardState extends State<GymSetupWizard> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Step 1 — Gym Name
  final _gymNameController = TextEditingController();
  final _gymNameFormKey = GlobalKey<FormState>();

  // Step 2 — Logo
  XFile? _selectedLogoFile;
  Uint8List? _selectedLogoBytes;
  String? _uploadedLogoUrl; // set after uploading to backend
  bool _isUploadingLogo = false;

  // Step 3 — Colors
  Color _selectedPrimary = const Color(0xFFDC2626);
  Color _selectedSecondary = const Color(0xFFEF4444);

  // Step 4 — Language
  String _selectedLanguage = 'ar';

  // Pre-defined palette the owner can pick from
  static const List<Color> _colorPalette = [
    Color(0xFFDC2626), // Red
    Color(0xFFEF4444), // Light Red
    Color(0xFFB91C1C), // Dark Red
    Color(0xFFF97316), // Orange
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Emerald
    Color(0xFF14B8A6), // Teal
    Color(0xFF3B82F6), // Blue
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Violet
    Color(0xFFA855F7), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFF84CC16), // Lime
    Color(0xFF78716C), // Stone
    Color(0xFF64748B), // Slate
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _gymNameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_gymNameFormKey.currentState!.validate()) return;
    }
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _submitSetup();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitSetup() async {
    setState(() => _isSubmitting = true);

    try {
      final branding = context.read<GymBrandingProvider>();
      final apiService = context.read<ApiService>();

      // Upload logo file first if one was picked but not yet uploaded
      if (_selectedLogoFile != null && _uploadedLogoUrl == null) {
        _uploadedLogoUrl = await _uploadLogo(apiService);
      }

      // Build hex strings from selected colors
      final primaryHex = '#${_selectedPrimary.value.toRadixString(16).substring(2).toUpperCase()}';
      final secondaryHex = '#${_selectedSecondary.value.toRadixString(16).substring(2).toUpperCase()}';

      // Send to backend
      final response = await apiService.put('/api/gyms/setup', data: {
        'name': _gymNameController.text.trim(),
        'primary_color': primaryHex,
        'secondary_color': secondaryHex,
        if (_uploadedLogoUrl != null) 'logo_url': _uploadedLogoUrl,
        'is_setup_complete': true,
      });

      final responseData = response.data;
      final gymJson = responseData['data'] as Map<String, dynamic>?;

      // Update local provider
      if (gymJson != null) {
        branding.loadFromGym(GymModel.fromJson(gymJson));
      } else {
        branding.updateBranding(
          gymName: _gymNameController.text.trim(),
          primaryColor: _selectedPrimary,
          secondaryColor: _selectedSecondary,
          logoUrl: _uploadedLogoUrl,
          isSetupComplete: true,
        );
      }

      // Save the owner's language preference (step 4) — failure here
      // shouldn't block finishing setup, since it's not critical data.
      try {
        await apiService.patch(
          '/api/auth/language',
          data: {'preferred_language': _selectedLanguage},
        );
      } catch (e) {
        debugPrint('Failed to save language preference: $e');
      }
      if (mounted) {
        context.read<LocaleProvider>().setArabic(_selectedLanguage == 'ar');
      }

      if (mounted) {
        // Navigate to owner dashboard — GoRouter redirect handles it
        context.go('/owner');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = [S.gymName, S.logo, S.brandColors, S.preferredLanguage];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.setupYourGym,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    S.stepOf(_currentStep + 1),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.mutedText,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Progress bar
                  Row(
                    children: List.generate(4, (i) {
                      final isActive = i <= _currentStep;
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Theme.of(context).colorScheme.primary
                                : AppTheme.edge,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1GymName(context),
                  _buildStep2Logo(context),
                  _buildStep3Colors(context),
                  _buildStep4Language(context),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : _previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(S.back),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _nextStep,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSubmitting
                          ? const SmallLoadingIndicator()
                          : Text(
                              _currentStep < 3 ? S.continueText : S.finishSetup,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 1 — Gym Name
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep1GymName(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _gymNameFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),

            Text(
              S.whatsYourGymCalled,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              S.gymNameAppears,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedText,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            TextFormField(
              controller: _gymNameController,
              decoration: InputDecoration(
                labelText: S.gymName,
                hintText: S.gymNameHint,
                prefixIcon: Icon(Icons.store),
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return S.pleaseEnterGymName;
                }
                if (value.trim().length < 2) {
                  return S.nameTooShort;
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Preview
            if (_gymNameController.text.trim().isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.edge),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email, size: 16, color: AppTheme.mutedText),
                    const SizedBox(width: 8),
                    Text(
                      'Customer emails: name@${_gymNameController.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}.com',
                      style: TextStyle(color: AppTheme.mutedText, fontSize: 13),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ──────────── Logo picking & uploading ────────────

  Future<void> _pickLogo(ImageSource source) async {
    try {
      if (kIsWeb && source == ImageSource.camera) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera upload is not supported on web.')),
          );
        }
        return;
      }

      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.fileNotFound), backgroundColor: Colors.red),
          );
        }
        return;
      }

      setState(() {
        _selectedLogoFile = picked;
        _selectedLogoBytes = bytes;
        _uploadedLogoUrl = null; // reset — will upload on submit
      });
    } catch (e) {
      debugPrint('Image picker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(S.chooseFromGallery),
              onTap: () {
                Navigator.pop(ctx);
                _pickLogo(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(S.takePhoto),
              enabled: !kIsWeb,
              onTap: () {
                Navigator.pop(ctx);
                _pickLogo(ImageSource.camera);
              },
            ),
            if (_selectedLogoFile != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(S.removeLogo, style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _selectedLogoFile = null;
                    _selectedLogoBytes = null;
                    _uploadedLogoUrl = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Upload the selected file to the backend and return the server URL.
  Future<String?> _uploadLogo(ApiService apiService) async {
    if (_selectedLogoFile == null) return null;

    try {
      final formData = FormData.fromMap({
        'logo': MultipartFile.fromBytes(
          _selectedLogoBytes ?? await _selectedLogoFile!.readAsBytes(),
          filename: _selectedLogoFile!.name,
        ),
      });

      final response = await apiService.post(
        '/api/gyms/upload-logo',
        data: formData,
      );

      final data = response.data;
      if (data['success'] == true) {
        return (data['data'] as Map<String, dynamic>)['logo_url'] as String?;
      }
    } catch (e) {
      debugPrint('Logo upload failed: $e');
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 2 — Logo
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep2Logo(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),

          Text(
            S.uploadGymLogo,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            S.logoShownOn,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedText,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Logo preview / upload area
          GestureDetector(
            onTap: _showPickerOptions,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
              child: _selectedLogoFile != null && _selectedLogoBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.memory(
                        _selectedLogoBytes!,
                        fit: BoxFit.cover,
                        width: 180,
                        height: 180,
                        errorBuilder: (_, error, ___) {
                          debugPrint('Logo Image.file error: $error');
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 48, color: Colors.red[400]),
                                const SizedBox(height: 8),
                                Text(S.cannotDisplayImage, style: TextStyle(color: Colors.red[400], fontSize: 12)),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  : _buildUploadPlaceholder(context),
            ),
          ),

          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _showPickerOptions,
            icon: Icon(
              _selectedLogoFile != null ? Icons.edit : Icons.cloud_upload,
              size: 18,
            ),
            label: Text(_selectedLogoFile != null ? S.changeLogo : S.chooseLogo),
          ),

          const SizedBox(height: 24),

          // Skip hint
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppTheme.mutedText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    S.skipLogoHint,
                    style: TextStyle(color: AppTheme.mutedText, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadPlaceholder(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
        ),
        const SizedBox(height: 8),
        Text(
          S.tapToUpload,
          style: TextStyle(
            color: AppTheme.mutedText,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 3 — Brand Colors
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep3Colors(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),

          Text(
            S.chooseYourBrandColors,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            S.colorsUsedThroughout,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedText,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Primary color picker
          Text(
            S.primaryColor,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            S.usedForButtons,
            style: TextStyle(color: AppTheme.mutedText, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _buildColorGrid(
            selectedColor: _selectedPrimary,
            onColorSelected: (c) => setState(() => _selectedPrimary = c),
          ),

          const SizedBox(height: 32),

          // Secondary color picker
          Text(
            S.secondaryColor,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            S.usedForSecondary,
            style: TextStyle(color: AppTheme.mutedText, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _buildColorGrid(
            selectedColor: _selectedSecondary,
            onColorSelected: (c) => setState(() => _selectedSecondary = c),
          ),

          const SizedBox(height: 32),

          // Preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _selectedPrimary.withOpacity(0.15),
                  _selectedSecondary.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _selectedPrimary.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                Text(
                  S.preview,
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _gymNameController.text.trim().isEmpty
                      ? S.yourGym
                      : _gymNameController.text.trim(),
                  style: TextStyle(
                    color: _selectedPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedPrimary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(S.primary),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _selectedSecondary,
                        side: BorderSide(color: _selectedSecondary),
                      ),
                      child: Text(S.secondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 4 — Preferred Language
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep4Language(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.language,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),

          Text(
            S.chooseYourLanguage,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            S.languageUsedThroughout,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedText,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          _buildLanguageOption(
            code: 'ar',
            label: S.arabicLanguageName,
            icon: Icons.translate,
          ),
          const SizedBox(height: 16),
          _buildLanguageOption(
            code: 'en',
            label: S.englishLanguageName,
            icon: Icons.translate,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required String code,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedLanguage == code;
    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.12) : AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : AppTheme.edge,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).colorScheme.primary : AppTheme.mutedText,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildColorGrid({
    required Color selectedColor,
    required ValueChanged<Color> onColorSelected,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _colorPalette.map((color) {
        final isSelected = color.value == selectedColor.value;
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.6),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
