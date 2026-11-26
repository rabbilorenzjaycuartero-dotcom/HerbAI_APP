import 'dart:async';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../core/app_theme.dart';
import '../core/context_extensions.dart';
import '../services/admin_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/report_service.dart';
import '../widgets/custom_appbar.dart';

/// Admin Usage Reports, built to stay usable with thousands of users:
/// - Overview: server-computed totals, activity trend and top lists;
/// - Users: search + filters, 25 per page ("Load more");
/// - Activity: chatbot/checklist records with search + filters, 25 per page.
/// Exports: a short PDF summary and an Excel file with all the data.
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  ReportRange _range = ReportRange.last30Days;
  bool _exportingPdf = false;
  bool _exportingExcel = false;
  final _usersKey = GlobalKey<_UsersTabState>();
  final _logsKey = GlobalKey<_ActivityTabState>();
  final _overviewKey = GlobalKey<_OverviewTabState>();

  @override
  void initState() {
    super.initState();
    AdminService.log('open_reports');
  }

  void _setRange(ReportRange range) {
    if (range == _range) return;
    setState(() => _range = range);
  }

  Future<void> _exportPdf() async {
    if (_exportingPdf) return;
    final failed = context.trRead('report_export_failed');
    setState(() => _exportingPdf = true);
    try {
      final summary = await ReportService.fetchSummary(_range);
      final user = FirebaseAuthService.currentUser;
      final bytes = await ReportService.buildPdf(summary, generatedBy: user?.displayName ?? user?.email ?? 'Admin');
      final stamp = ReportService.formatDate(summary.generatedAt);
      await Printing.sharePdf(bytes: bytes, filename: 'HerbAI_Usage_Report_$stamp.pdf');
      AdminService.log('export_pdf', details: {'range': ReportService.rangeLabel(_range)});
    } catch (e) {
      debugPrint('PDF export failed: $e');
      _snack(failed);
    }
    if (mounted) setState(() => _exportingPdf = false);
  }

  Future<void> _exportExcel() async {
    if (_exportingExcel) return;
    final failed = context.trRead('report_export_failed');
    setState(() => _exportingExcel = true);
    try {
      final bytes = await ReportService.downloadExcel(_range);
      final stamp = ReportService.formatDate(DateTime.now());
      await Share.shareXFiles([
        XFile.fromData(
          bytes,
          name: 'HerbAI_Usage_Data_$stamp.xlsx',
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ], fileNameOverrides: ['HerbAI_Usage_Data_$stamp.xlsx']);
    } catch (e) {
      debugPrint('Excel export failed: $e');
      _snack(failed);
    }
    if (mounted) setState(() => _exportingExcel = false);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  Widget _exportButton(String tooltip, IconData icon, bool busy, VoidCallback onTap) {
    return IconButton(
      tooltip: tooltip,
      onPressed: busy ? null : onTap,
      icon: busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: CustomAppBar(
          title: context.tr('reports_title'),
          actions: [
            _exportButton(context.tr('report_export_pdf'), Icons.picture_as_pdf_outlined, _exportingPdf, _exportPdf),
            _exportButton(context.tr('report_export_excel'), Icons.table_view_outlined, _exportingExcel, _exportExcel),
          ],
        ),
        body: Column(
          children: [
            Material(
              color: AppTheme.background,
              child: TabBar(
                labelColor: AppTheme.primary,
                indicatorColor: AppTheme.primary,
                tabs: [
                  Tab(text: context.tr('report_tab_overview')),
                  Tab(text: context.tr('report_tab_users')),
                  Tab(text: context.tr('report_tab_activity')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final entry in {
                      ReportRange.last7Days: context.tr('report_last_7_days'),
                      ReportRange.last30Days: context.tr('report_last_30_days'),
                      ReportRange.allTime: context.tr('report_all_time'),
                    }.entries)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(entry.value),
                          selected: _range == entry.key,
                          onSelected: (_) => _setRange(entry.key),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _OverviewTab(key: _overviewKey, range: _range),
                  _UsersTab(key: _usersKey),
                  _ActivityTab(key: _logsKey, range: _range),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// Overview tab
// ======================================================================

class _OverviewTab extends StatefulWidget {
  final ReportRange range;
  const _OverviewTab({super.key, required this.range});

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> with AutomaticKeepAliveClientMixin {
  ReportSummary? _summary;
  String? _error;
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _OverviewTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.range != widget.range) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await ReportService.fetchSummary(widget.range);
      if (mounted) setState(() => _summary = summary);
    } catch (e) {
      debugPrint('Summary load failed: $e');
      if (mounted) setState(() => _error = context.trRead('report_load_failed'));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = _summary;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (_loading && s == null)
            const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CircularProgressIndicator()))
          else if (_error != null && s == null)
            _errorBox(context, _error!, _load)
          else if (s != null) ...[
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Row(children: [
              _stat(context.tr('report_registered_users'), s.registeredUsers, Icons.people_outline),
              const SizedBox(width: 8),
              _stat(context.tr('report_active_users'), s.activeUsers, Icons.person_search_outlined),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _stat(context.tr('report_chat_messages'), s.chatMessages, Icons.chat_outlined),
              const SizedBox(width: 8),
              _stat(context.tr('report_checklist_searches'), s.checklistSearches, Icons.checklist_rounded),
            ]),
            _section(context.tr('report_activity_trend'), _trend(context, s)),
            _section(context.tr('report_top_concerns'), _bars(s.topConcerns, s.concernTotal)),
            _section(context.tr('report_users_by_designation'), _bars(s.usersByDesignation, s.registeredUsers)),
            _section(context.tr('report_users_by_age'), _bars(s.usersByAgeGroup, s.registeredUsers)),
            _section(context.tr('report_concerns_by_designation'), _groups(s.concernsByDesignation)),
            _section(context.tr('report_concerns_by_age'), _groups(s.concernsByAgeGroup)),
            _section(context.tr('report_top_words'), _bars(s.topWords, s.chatMessages)),
            _section(context.tr('report_top_herbs'), _bars(s.topHerbs, s.topHerbs.fold(0, (n, e) => n + e.count))),
            const SizedBox(height: 12),
            Text(
              '${context.tr('report_generated')} ${ReportService.formatDate(s.generatedAt, withTime: true)}',
              style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(String label, int value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_compact(value), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  /// Vertical bars per day (or month for "All time"); chatbot + checklist.
  Widget _trend(BuildContext context, ReportSummary s) {
    if (s.trend.every((t) => t.total == 0)) return _noData(context);
    final max = s.trend.map((t) => t.total).reduce((a, b) => a > b ? a : b);
    final showEvery = s.trend.length > 12 ? (s.trend.length / 6).ceil() : 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 130,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final t in s.trend)
                Expanded(
                  child: Tooltip(
                    message: '${t.label}: ${t.chatbot} chat, ${t.checklist} checklist',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: max == 0 ? 0 : 120 * t.checklist / max,
                            color: AppTheme.secondary,
                          ),
                          Container(
                            height: max == 0 ? 0 : 120 * t.chatbot / max,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (var i = 0; i < s.trend.length; i++)
              Expanded(
                child: i % showEvery == 0
                    ? Text(
                        s.trend[i].label.substring(5),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 9, color: AppTheme.textSecondary),
                      )
                    : const SizedBox.shrink(),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _legend(AppTheme.primary, context.tr('report_legend_chatbot')),
            const SizedBox(width: 14),
            _legend(AppTheme.secondary, context.tr('report_legend_checklist')),
          ],
        ),
      ],
    );
  }

  Widget _legend(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary)),
        ],
      );

  Widget _bars(List<CountRow> rows, int total) {
    if (rows.isEmpty) return _noData(context);
    final max = rows.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 112,
                  child: Text(row.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) => Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 14,
                        width: c.maxWidth * (row.count / max),
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
                  width: 84,
                  child: Text(
                    total == 0
                        ? _compact(row.count)
                        : '${_compact(row.count)} (${(row.count * 100 / total).toStringAsFixed(0)}%)',
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

  Widget _groups(List<GroupTop> groups) {
    if (groups.isEmpty) return _noData(context);
    return Column(
      children: [
        for (final g in groups)
          Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              dense: true,
              title: Text(g.group, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(g.top.map((e) => '${e.label} (${e.count})').join(', ')),
            ),
          ),
      ],
    );
  }
}

// ======================================================================
// Users tab
// ======================================================================

class _UsersTab extends StatefulWidget {
  const _UsersTab({super.key});

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> with AutomaticKeepAliveClientMixin {
  final _search = TextEditingController();
  Timer? _debounce;
  String _designation = '';
  String _ageGroup = '';
  final List<ReportUser> _items = [];
  int _total = 0;
  int? _nextOffset = 0;
  bool _loading = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _reload() {
    _items.clear();
    _nextOffset = 0;
    _total = 0;
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || _nextOffset == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ReportService.fetchUsers(
        query: _search.text.trim(),
        designation: _designation,
        ageGroup: _ageGroup,
        offset: _nextOffset!,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _total = page.total;
        _nextOffset = page.nextOffset;
      });
    } catch (e) {
      debugPrint('Users load failed: $e');
      if (mounted) setState(() => _error = context.trRead('report_load_failed'));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _SearchField(
            controller: _search,
            hint: context.tr('report_search_users'),
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 400), () => setState(_reload));
            },
          ),
        ),
        _FilterRow(children: [
          _FilterDropdown(
            label: context.tr('designation_hint'),
            value: _designation,
            options: ReportService.designations,
            onChanged: (v) => setState(() {
              _designation = v;
              _reload();
            }),
          ),
          _FilterDropdown(
            label: context.tr('age_hint'),
            value: _ageGroup,
            options: ReportService.ageGroups,
            onChanged: (v) => setState(() {
              _ageGroup = v;
              _reload();
            }),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$_total ${context.tr('report_results')}',
              style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        Expanded(
          child: _PagedList(
            itemCount: _items.length,
            hasMore: _nextOffset != null,
            loading: _loading,
            error: _error,
            onLoadMore: _loadMore,
            onRefresh: () async => setState(_reload),
            itemBuilder: (context, i) {
              final u = _items[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                    child: Text(
                      u.name.isEmpty ? '?' : u.name[0].toUpperCase(),
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(u.name.isEmpty ? u.email : u.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${u.designation} · ${u.age ?? '-'} · ${u.email}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(ReportService.formatDate(u.createdAt), style: const TextStyle(fontSize: 11.5)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ======================================================================
// Activity tab
// ======================================================================

class _ActivityTab extends StatefulWidget {
  final ReportRange range;
  const _ActivityTab({super.key, required this.range});

  @override
  State<_ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<_ActivityTab> with AutomaticKeepAliveClientMixin {
  final _search = TextEditingController();
  Timer? _debounce;
  String _source = '';
  String _designation = '';
  final List<ReportLog> _items = [];
  int _total = 0;
  int? _nextOffset = 0;
  bool _loading = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant _ActivityTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.range != widget.range) setState(_reload);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _reload() {
    _items.clear();
    _nextOffset = 0;
    _total = 0;
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || _nextOffset == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ReportService.fetchLogs(
        range: widget.range,
        query: _search.text.trim(),
        source: _source,
        designation: _designation,
        offset: _nextOffset!,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _total = page.total;
        _nextOffset = page.nextOffset;
      });
    } catch (e) {
      debugPrint('Logs load failed: $e');
      if (mounted) setState(() => _error = context.trRead('report_load_failed'));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _SearchField(
            controller: _search,
            hint: context.tr('report_search_logs'),
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 400), () => setState(_reload));
            },
          ),
        ),
        _FilterRow(children: [
          _FilterDropdown(
            label: context.tr('report_source'),
            value: _source,
            options: const ['chatbot', 'checklist'],
            optionLabel: (v) => context.tr(v == 'chatbot' ? 'report_legend_chatbot' : 'report_legend_checklist'),
            onChanged: (v) => setState(() {
              _source = v;
              _reload();
            }),
          ),
          _FilterDropdown(
            label: context.tr('designation_hint'),
            value: _designation,
            options: ReportService.designations,
            onChanged: (v) => setState(() {
              _designation = v;
              _reload();
            }),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$_total ${context.tr('report_results')}',
              style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        Expanded(
          child: _PagedList(
            itemCount: _items.length,
            hasMore: _nextOffset != null,
            loading: _loading,
            error: _error,
            onLoadMore: _loadMore,
            onRefresh: () async => setState(_reload),
            itemBuilder: (context, i) {
              final l = _items[i];
              final isChecklist = l.source == 'checklist';
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: (isChecklist ? AppTheme.secondary : AppTheme.primary).withValues(alpha: 0.15),
                    child: Icon(
                      isChecklist ? Icons.checklist_rounded : Icons.chat_bubble_outline_rounded,
                      size: 17,
                      color: isChecklist ? Colors.orange.shade800 : AppTheme.primary,
                    ),
                  ),
                  title: Text(
                    isChecklist ? context.tr('report_checklist_entry') : '"${l.message}"',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${ReportService.formatDate(l.createdAt, withTime: true)} · '
                    '${l.userName.isEmpty ? '-' : l.userName} · ${l.designation}${l.age != null ? ', ${l.age}' : ''}'
                    '${l.detectedSymptoms.isEmpty ? '' : '\n${context.tr('report_detected')}: ${l.detectedSymptoms.join(', ')}'}',
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ======================================================================
// Shared pieces
// ======================================================================

String _compact(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 10000) return '${(n / 1000).toStringAsFixed(1)}k';
  return '$n';
}

Widget _noData(BuildContext context) =>
    Text(context.tr('report_no_data'), style: TextStyle(color: AppTheme.textSecondary));

Widget _errorBox(BuildContext context, String message, VoidCallback onRetry) => Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: Text(context.tr('retry'))),
        ],
      ),
    );

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final List<Widget> children;
  const _FilterRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}

/// Compact dropdown; '' means "All".
class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final String Function(String)? optionLabel;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.optionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: [
        DropdownMenuItem(value: '', child: Text(context.tr('filter_all'))),
        for (final o in options)
          DropdownMenuItem(value: o, child: Text(optionLabel?.call(o) ?? o, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (v) => onChanged(v ?? ''),
    );
  }
}

/// List with pull-to-refresh and a "Load more" footer (25 per page).
class _PagedList extends StatelessWidget {
  final int itemCount;
  final bool hasMore;
  final bool loading;
  final String? error;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;
  final IndexedWidgetBuilder itemBuilder;

  const _PagedList({
    required this.itemCount,
    required this.hasMore,
    required this.loading,
    required this.error,
    required this.onLoadMore,
    required this.onRefresh,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        itemCount: itemCount + 1,
        itemBuilder: (context, i) {
          if (i < itemCount) return itemBuilder(context, i);
          if (loading) {
            return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
          }
          if (error != null) return _errorBox(context, error!, onLoadMore);
          if (itemCount == 0) {
            return Padding(padding: const EdgeInsets.only(top: 40), child: Center(child: _noData(context)));
          }
          if (!hasMore) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(context.tr('report_end_of_list'),
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: OutlinedButton.icon(
                onPressed: onLoadMore,
                icon: const Icon(Icons.expand_more_rounded),
                label: Text(context.tr('report_load_more')),
              ),
            ),
          );
        },
      ),
    );
  }
}
