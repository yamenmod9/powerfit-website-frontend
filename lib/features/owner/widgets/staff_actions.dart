import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/utils/role_utils.dart';

/// Trailing action menu for a staff row — Edit and Activate/Deactivate.
///
/// Shared by the owner, regional manager and branch manager staff lists so a
/// manager can actually manage staff, not just look at them. Actions only
/// appear for staff the viewer outranks; the backend enforces the same rule
/// plus branch scope, so this is UI convenience, not the security boundary.
class StaffActions extends StatefulWidget {
  final Map<String, dynamic> staff;
  final ApiService apiService;

  /// The signed-in user's role — actions are hidden for peers/superiors.
  final String? viewerRole;

  /// Called after a successful edit/toggle so the host can refresh.
  final VoidCallback onChanged;

  const StaffActions({
    super.key,
    required this.staff,
    required this.apiService,
    required this.viewerRole,
    required this.onChanged,
  });

  @override
  State<StaffActions> createState() => _StaffActionsState();
}

class _StaffActionsState extends State<StaffActions> {
  bool _busy = false;

  int? get _staffId {
    final raw = widget.staff['id'] ?? widget.staff['user_id'] ?? widget.staff['staff_id'];
    return raw is int ? raw : int.tryParse(raw?.toString() ?? '');
  }

  String get _staffRole => (widget.staff['role'] ?? '').toString();

  bool get _isActive {
    final raw = widget.staff['is_active'];
    if (raw is bool) return raw;
    if (raw == null) return true;
    final s = raw.toString().toLowerCase();
    return s == 'true' || s == '1';
  }

  bool get _canManage =>
      _staffId != null &&
      RoleUtils.outranks(widget.viewerRole, _staffRole);

  Future<void> _toggleActive() async {
    setState(() => _busy = true);
    try {
      await widget.apiService.put(
        '/api/users/$_staffId',
        data: {'is_active': !_isActive},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isActive ? S.staffDeactivated : S.staffActivated),
          backgroundColor: Colors.green,
        ),
      );
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${S.error}: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _EditStaffDialog(
        staff: widget.staff,
        apiService: widget.apiService,
        staffId: _staffId!,
      ),
    );
    if (changed == true) widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    if (!_canManage) return const SizedBox.shrink();
    if (_busy) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'edit') _edit();
        if (value == 'toggle') _toggleActive();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit, size: 18),
              const SizedBox(width: 8),
              Text(S.edit),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'toggle',
          child: Row(
            children: [
              Icon(_isActive ? Icons.block : Icons.check_circle,
                  size: 18, color: _isActive ? Colors.red : Colors.green),
              const SizedBox(width: 8),
              Text(_isActive ? S.deactivate : S.activate),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditStaffDialog extends StatefulWidget {
  final Map<String, dynamic> staff;
  final ApiService apiService;
  final int staffId;

  const _EditStaffDialog({
    required this.staff,
    required this.apiService,
    required this.staffId,
  });

  @override
  State<_EditStaffDialog> createState() => _EditStaffDialogState();
}

class _EditStaffDialogState extends State<_EditStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
        text: (widget.staff['full_name'] ?? '').toString());
    _phoneController = TextEditingController(
        text: (widget.staff['phone'] ?? '').toString());
    _emailController = TextEditingController(
        text: (widget.staff['email'] ?? '').toString());
    final raw = widget.staff['is_active'];
    _isActive = raw is bool ? raw : (raw?.toString().toLowerCase() != 'false');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.apiService.put('/api/users/${widget.staffId}', data: {
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'is_active': _isActive,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${S.error}: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.editStaffMember),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: S.fullNameRequired,
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? S.required : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: S.phoneOptional,
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: S.emailRequired,
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return S.required;
                  if (!v.contains('@')) return S.invalidEmail;
                  return null;
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(S.active),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text(S.cancel),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(S.save),
        ),
      ],
    );
  }
}
