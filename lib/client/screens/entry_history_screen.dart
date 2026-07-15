import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:go_router/go_router.dart';
import '../../core/localization/app_strings.dart';
import '../core/api/client_api_service.dart';
import '../core/theme/client_theme.dart';
import '../models/entry_history_model.dart';

/// Visit history, styled to the PowerFit Member App design: a lean list of
/// dark cards, each with a crimson status glyph, the visit date, branch, and
/// the check-in time.
class EntryHistoryScreen extends StatefulWidget {
  const EntryHistoryScreen({super.key});

  @override
  State<EntryHistoryScreen> createState() => _EntryHistoryScreenState();
}

class _EntryHistoryScreenState extends State<EntryHistoryScreen> {
  List<EntryHistoryModel> _entries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ClientApiService>();
      final response = await apiService.getEntryHistory();

      if (response['status'] == 'success' || response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        setState(() {
          _entries =
              data.map((entry) => EntryHistoryModel.fromJson(entry)).toList();
        });
      } else {
        setState(() =>
            _error = response['message'] ?? 'Failed to load entry history');
      }
    } catch (e) {
      setState(() => _error = S.entryHistoryNotAvailable);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ClientTheme.darkGrey,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Row(
        children: [
          if (context.canPop())
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          if (context.canPop()) const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.entryHistoryTitle,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(S.recentVisits,
                  style: const TextStyle(
                      color: ClientTheme.subtleGrey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: ClientTheme.primaryRed));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 64, color: ClientTheme.primaryRed),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _loadEntries, child: Text(S.retry)),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: ClientTheme.primaryRed,
      onRefresh: _loadEntries,
      child: _entries.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Icon(Icons.history, size: 64, color: Color(0xFF243050)),
                const SizedBox(height: 16),
                Center(
                  child: Text(S.noEntryHistory,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(S.visitsAppearHere,
                      style: TextStyle(color: ClientTheme.subtleGrey)),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
              itemCount: _entries.length,
              separatorBuilder: (_, i) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _entryCard(_entries[index]),
            ),
    );
  }

  Widget _entryCard(EntryHistoryModel entry) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('HH:mm');
    final bool isApproved = entry.isApproved;
    final Color color =
        isApproved ? ClientTheme.primaryRed : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ClientTheme.cardGrey,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(isApproved ? Icons.check_rounded : Icons.close_rounded,
                color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateFormat.format(entry.dateTime),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(entry.branch,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: ClientTheme.subtleGrey, fontSize: 12)),
              ],
            ),
          ),
          if (entry.coinsUsed > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsetsDirectional.only(end: 10),
              decoration: BoxDecoration(
                color: ClientTheme.primaryRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('-${entry.coinsUsed}',
                  style: const TextStyle(
                      color: ClientTheme.primaryRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          ],
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(timeFormat.format(entry.dateTime),
                style: const TextStyle(
                    color: ClientTheme.textGrey,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
