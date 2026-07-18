import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_service.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/utils/role_utils.dart';

/// Staff-to-staff issues: raise a problem upward, and see what's been raised
/// to you. Deliberately separate from member complaints — complaints face the
/// whole team, issues face up the chain.
///
/// Self-contained on [ApiService] so it can drop into any staff console as a
/// tab (embedded) or stand alone.
class IssuesScreen extends StatefulWidget {
  final bool embedded;
  const IssuesScreen({super.key, this.embedded = false});

  @override
  State<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends State<IssuesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _issues = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int? get _myId => int.tryParse(context.read<AuthProvider>().userId ?? '');

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await context.read<ApiService>().get('/api/issues');
      final data = res.data['data'] ?? res.data;
      final list = (data is List ? data : <dynamic>[])
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
      setState(() {
        _issues = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _inbox =>
      _issues.where((i) => i['reported_by_id'] != _myId).toList();

  List<Map<String, dynamic>> get _mine =>
      _issues.where((i) => i['reported_by_id'] == _myId).toList();

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Material(
          color: Colors.transparent,
          child: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: '${S.issuesInbox} (${_inbox.length})'),
              Tab(text: '${S.issuesRaised} (${_mine.length})'),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _errorView()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _issueList(_inbox, isInbox: true),
                        _issueList(_mine, isInbox: false),
                      ],
                    ),
        ),
      ],
    );

    final fab = FloatingActionButton.extended(
      onPressed: _showCreateDialog,
      icon: const Icon(Icons.add),
      label: Text(S.raiseIssue),
    );

    if (widget.embedded) {
      return Stack(
        children: [
          content,
          Positioned(right: 16, bottom: 16, child: fab),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(S.issues),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: fab,
      body: content,
    );
  }

  Widget _errorView() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, maxLines: 3),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: Text(S.retry)),
          ],
        ),
      );

  Widget _issueList(List<Map<String, dynamic>> items, {required bool isInbox}) {
    if (items.isEmpty) {
      return Center(
        child: Text(isInbox ? S.noIssuesInbox : S.noIssuesRaised,
            style: const TextStyle(color: Color(0xFF9AA3B8))),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        itemCount: items.length,
        itemBuilder: (_, i) => _issueCard(items[i]),
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'resolved' => Colors.green,
        'in_progress' => Colors.blue,
        _ => Colors.orange,
      };

  Color _priorityColor(String p) => switch (p) {
        'high' => Colors.red,
        'medium' => Colors.orange,
        _ => const Color(0xFF9AA3B8),
      };

  Widget _issueCard(Map<String, dynamic> issue) {
    final status = (issue['status'] ?? 'open').toString();
    final priority = (issue['priority'] ?? 'medium').toString();
    final reporter = (issue['reported_by_name'] ?? S.unknown).toString();
    final reporterRole =
        RoleUtils.getRoleDisplayName(issue['reported_by_role']?.toString());
    final assignee = issue['assigned_to_name']?.toString();
    final branch = issue['branch_name']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _showDetail(issue),
        leading: Container(
          width: 6,
          height: double.infinity,
          color: _priorityColor(priority),
        ),
        title: Text(issue['title']?.toString() ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '$reporter · $reporterRole${branch != null && branch.isNotEmpty ? ' · $branch' : ''}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF9AA3B8)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (assignee != null && assignee.isNotEmpty)
              Text('${S.assignedTo}: $assignee',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7590))),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _statusColor(status).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _statusLabel(status),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _statusColor(status)),
          ),
        ),
      ),
    );
  }

  String _statusLabel(String s) => switch (s) {
        'resolved' => S.statusResolved,
        'in_progress' => S.statusInProgress,
        _ => S.statusOpen,
      };

  Future<void> _showDetail(Map<String, dynamic> issue) async {
    final id = issue['id'] as int;
    final notesController =
        TextEditingController(text: (issue['resolution_notes'] ?? '').toString());
    String status = (issue['status'] ?? 'open').toString();
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(issue['title']?.toString() ?? '',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(issue['description']?.toString() ?? '',
                    style: const TextStyle(color: Color(0xFF6B7590))),
                const SizedBox(height: 16),
                Text(S.status, style: Theme.of(ctx).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['open', 'in_progress', 'resolved'].map((s) {
                    final selected = status == s;
                    return ChoiceChip(
                      label: Text(_statusLabel(s)),
                      selected: selected,
                      onSelected: (_) => setSheet(() => status = s),
                      selectedColor: _statusColor(s).withValues(alpha: 0.2),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: S.resolutionNotes,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: saving ? null : () => Navigator.pop(ctx),
                      child: Text(S.cancel),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              setSheet(() => saving = true);
                              try {
                                await context.read<ApiService>().put(
                                  '/api/issues/$id',
                                  data: {
                                    'status': status,
                                    'resolution_notes': notesController.text.trim(),
                                  },
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                await _load();
                              } catch (e) {
                                setSheet(() => saving = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('${S.error}: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(S.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const _CreateIssueDialog(),
    );
    if (created == true) _load();
  }
}

class _CreateIssueDialog extends StatefulWidget {
  const _CreateIssueDialog();

  @override
  State<_CreateIssueDialog> createState() => _CreateIssueDialogState();
}

class _CreateIssueDialogState extends State<_CreateIssueDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _priority = 'medium';
  int? _assigneeId;
  List<Map<String, dynamic>> _staff = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    try {
      final res =
          await context.read<ApiService>().get('/api/issues/assignable-staff');
      final data = res.data['data'] ?? res.data;
      if (mounted) {
        setState(() {
          _staff = (data is List ? data : <dynamic>[])
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<ApiService>().post('/api/issues', data: {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'priority': _priority,
        if (_assigneeId != null) 'assigned_to_id': _assigneeId,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${S.error}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.raiseIssue),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: S.issueTitle,
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? S.required : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: S.issueDescription,
                  prefixIcon: const Icon(Icons.description),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? S.required : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: InputDecoration(
                  labelText: S.priority,
                  prefixIcon: const Icon(Icons.flag),
                ),
                items: [
                  DropdownMenuItem(value: 'low', child: Text(S.priorityLow)),
                  DropdownMenuItem(value: 'medium', child: Text(S.priorityMedium)),
                  DropdownMenuItem(value: 'high', child: Text(S.priorityHigh)),
                ],
                onChanged: (v) => setState(() => _priority = v ?? 'medium'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                value: _assigneeId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: S.assignToOptional,
                  prefixIcon: const Icon(Icons.person),
                ),
                items: [
                  DropdownMenuItem<int?>(
                      value: null, child: Text(S.anyoneAbove)),
                  ..._staff.map((s) => DropdownMenuItem<int?>(
                        value: s['id'] as int?,
                        child: Text(
                          '${s['full_name']} · ${RoleUtils.getRoleDisplayName(s['role']?.toString())}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                ],
                onChanged: (v) => setState(() => _assigneeId = v),
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
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(S.send),
        ),
      ],
    );
  }
}
