import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../core/app_theme.dart';
import '../core/context_extensions.dart';
import '../services/firebase_auth_service.dart';
import '../services/report_service.dart';
import '../widgets/custom_appbar.dart';

/// Admin-only usage reports (panel revision): who uses the system (age,
/// designation) and what users ask the chatbot, with PDF export.
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  ReportRange _range = ReportRange.last30Days;
  UsageReport? _report;
  String? _error;
  bool _loading = true;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await ReportService.load(_range);
      if (!mounted) return;
      setState(() {
        _report = report;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Report load failed: $e');
      if (!mounted) return;
      setState(() {
        _error = context.trRead('report_load_failed');
        _loading = false;
      });
    }
  }

  Future<void> _exportPdf() async {
    final report = _report;
    if (report == null || _exporting) return;
    setState(() => _exporting = true);
    try {
      final user = FirebaseAuthService.currentUser;
      final bytes = await ReportService.buildPdf(
        report,
        generatedBy: user?.displayName ?? user?.email ?? 'Admin',
      );
      final stamp = ReportService.formatDate(report.generatedAt);
      await Printing.sharePdf(bytes: bytes, filename: 'HerbAI_Usage_Report_$stamp.pdf');
    } catch (e) {
      debugPrint('PDF export failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.trRead('report_export_failed')), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _exporting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: context.tr('reports_title'),
        actions: [
          IconButton(
            tooltip: context.tr('report_export_pdf'),
            onPressed: _report == null || _exporting ? null : _exportPdf,
            icon: _exporting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildRangeChips(),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: _load, child: Text(context.tr('retry'))),
                    ],
                  ),
                )
              else
                ..._buildReport(context, _report!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRangeChips() {
    final labels = {
      ReportRange.last7Days: context.tr('report_last_7_days'),
      ReportRange.last30Days: context.tr('report_last_30_days'),
      ReportRange.allTime: context.tr('report_all_time'),
    };
    return Wrap(
      spacing: 8,
      children: [
        for (final entry in labels.entries)
          ChoiceChip(
            label: Text(entry.value),
            selected: _range == entry.key,
            onSelected: (_) {
              if (_range == entry.key) return;
              setState(() => _range = entry.key);
              _load();
            },
          ),
      ],
    );
  }

  List<Widget> _buildReport(BuildContext context, UsageReport r) {
    final concernTotal = r.logs.fold<int>(0, (n, l) => n + l.detectedSymptoms.length);
    return [
      Row(
        children: [
          _stat(context.tr('report_registered_users'), r.users.length, Icons.people_outline),
          const SizedBox(width: 8),
          _stat(context.tr('report_active_users'), r.activeUsers, Icons.person_search_outlined),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          _stat(context.tr('report_chat_messages'), r.messageLogs.length, Icons.chat_outlined),
          const SizedBox(width: 8),
          _stat(context.tr('report_checklist_searches'), r.checklistLogs.length, Icons.checklist_rounded),
        ],
      ),
      _section(context.tr('report_users_by_designation'), _bars(r.usersByDesignation, r.users.length)),
      _section(context.tr('report_users_by_age'), _bars(r.usersByAgeGroup, r.users.length)),
      _section(context.tr('report_top_concerns'), _bars(r.topConcerns(), concernTotal)),
      _section(context.tr('report_concerns_by_designation'), _groups(r.concernsByDesignation)),
      _section(context.tr('report_concerns_by_age'), _groups(r.concernsByAgeGroup)),
      _section(context.tr('report_top_words'), _bars(r.topWords(), r.messageLogs.length)),
      _section(context.tr('report_top_herbs'), _bars(r.topHerbs(), r.logs.where((l) => l.recommendedHerbs.isNotEmpty).length)),
      _section(context.tr('report_recent_logs'), _recentLogs(r)),
      _section(context.tr('report_user_list'), _userList(r)),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _exporting ? null : _exportPdf,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: Text(context.tr('report_export_pdf')),
        ),
      ),
      const SizedBox(height: 16),
    ];
  }

  Widget _stat(String label, int value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primary),
              const SizedBox(height: 6),
              Text('$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _empty() => Text(context.tr('report_no_data'), style: TextStyle(color: AppTheme.textSecondary));

  Widget _bars(List<MapEntry<String, int>> rows, int total) {
    if (rows.isEmpty) return _empty();
    final max = rows.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(row.key, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 14,
                        width: constraints.maxWidth * (row.value / max),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 72,
                  child: Text(
                    total == 0 ? '${row.value}' : '${row.value} (${(row.value * 100 / total).toStringAsFixed(0)}%)',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _groups(Map<String, List<MapEntry<String, int>>> groups) {
    if (groups.isEmpty) return _empty();
    return Column(
      children: [
        for (final g in groups.entries)
          Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              dense: true,
              title: Text(g.key, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(g.value.map((e) => '${e.key} (${e.value})').join(', ')),
            ),
          ),
      ],
    );
  }

  Widget _recentLogs(UsageReport r) {
    final logs = r.messageLogs.take(50).toList();
    if (logs.isEmpty) return _empty();
    return Column(
      children: [
        for (final l in logs)
          Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              dense: true,
              title: Text('"${l.message}"'),
              subtitle: Text(
                '${ReportService.formatDate(l.createdAt, withTime: true)} · ${l.userName.isEmpty ? '-' : l.userName} · '
                '${l.designation}${l.age != null ? ', ${l.age}' : ''}'
                '${l.detectedSymptoms.isEmpty ? '' : '\n${context.tr('report_detected')}: ${l.detectedSymptoms.join(', ')}'}',
              ),
            ),
          ),
      ],
    );
  }

  Widget _userList(UsageReport r) {
    if (r.users.isEmpty) return _empty();
    return Column(
      children: [
        for (final u in r.users)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_outline),
            title: Text(u.name.isEmpty ? '-' : u.name),
            subtitle: Text('${u.designation} · ${u.age ?? '-'}'),
            trailing: Text(ReportService.formatDate(u.createdAt), style: const TextStyle(fontSize: 12)),
          ),
      ],
    );
  }
}
