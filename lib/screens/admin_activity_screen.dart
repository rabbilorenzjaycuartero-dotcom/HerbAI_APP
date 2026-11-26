import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/context_extensions.dart';
import '../services/admin_service.dart';
import '../services/report_service.dart';
import '../widgets/custom_appbar.dart';

/// Admin activity log: who opened the Usage Reports, exported a PDF, or
/// added/removed an admin, and when. Entries are written by the server.
class AdminActivityScreen extends StatefulWidget {
  const AdminActivityScreen({super.key});

  @override
  State<AdminActivityScreen> createState() => _AdminActivityScreenState();
}

class _AdminActivityScreenState extends State<AdminActivityScreen> {
  List<AdminLogEntry>? _entries;
  String? _error;
  String _filter = 'all';

  static const _filters = ['all', 'export_pdf', 'export_xlsx', 'open_reports', 'add_admin', 'remove_admin'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final entries = await AdminService.activityLog();
      if (mounted) setState(() => _entries = entries);
    } catch (e) {
      debugPrint('Load admin log failed: $e');
      if (mounted) setState(() => _error = context.trRead('report_load_failed'));
    }
  }

  (IconData, Color) _style(String action) {
    switch (action) {
      case 'export_pdf':
        return (Icons.picture_as_pdf_outlined, Colors.red.shade600);
      case 'export_xlsx':
        return (Icons.table_view_outlined, Colors.teal.shade600);
      case 'open_reports':
        return (Icons.bar_chart_rounded, AppTheme.primary);
      case 'add_admin':
        return (Icons.person_add_alt_1_rounded, Colors.blue.shade600);
      case 'remove_admin':
        return (Icons.person_remove_outlined, Colors.orange.shade800);
      default:
        return (Icons.history_rounded, AppTheme.textSecondary);
    }
  }

  String _describe(BuildContext context, AdminLogEntry e) {
    final d = e.details;
    switch (e.action) {
      case 'export_pdf':
        return '${context.tr('log_export_pdf')}${d['range'] != null ? ' (${d['range']})' : ''}';
      case 'export_xlsx':
        return '${context.tr('log_export_xlsx')}${d['range'] != null ? ' (${d['range']})' : ''}';
      case 'open_reports':
        return context.tr('log_open_reports');
      case 'add_admin':
        return '${context.tr('log_add_admin')} ${d['targetEmail'] ?? ''}';
      case 'remove_admin':
        return '${context.tr('log_remove_admin')} ${d['targetEmail'] ?? ''}';
      default:
        return e.action;
    }
  }

  String _filterLabel(BuildContext context, String f) =>
      f == 'all' ? context.tr('filter_all') : context.tr('log_filter_$f');

  @override
  Widget build(BuildContext context) {
    final entries = _entries?.where((e) => _filter == 'all' || e.action == _filter).toList();
    return Scaffold(
      appBar: CustomAppBar(title: context.tr('admin_activity_log')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final f in _filters)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(_filterLabel(context, f)),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Center(child: Text(_error!))
              else if (entries == null)
                const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: CircularProgressIndicator()))
              else if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(context.tr('report_no_data'), style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                )
              else
                for (final e in entries)
                  Builder(builder: (context) {
                    final (icon, color) = _style(e.action);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.12),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        title: Text(_describe(context, e), style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${e.actorName.isEmpty ? e.actorEmail : '${e.actorName} (${e.actorEmail})'}\n'
                          '${ReportService.formatDate(e.createdAt, withTime: true)}',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
