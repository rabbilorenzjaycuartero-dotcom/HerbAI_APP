import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../core/app_constants.dart';
import 'firebase_auth_service.dart';

/// Admin usage reports (panel revision). The SERVER computes the summary and
/// serves the user list / activity log in pages of 25 (see admin_reports.py),
/// so the numbers stay correct with thousands of users. This service calls
/// those endpoints, builds the PDF summary, and downloads the Excel export.

enum ReportRange { last7Days, last30Days, allTime }

class CountRow {
  final String label;
  final int count;
  const CountRow(this.label, this.count);

  static List<CountRow> listFrom(Object? json) => ((json as List<dynamic>?) ?? [])
      .map((e) => CountRow((e as Map<String, dynamic>)['label'] as String, (e['count'] as num).toInt()))
      .toList();
}

class GroupTop {
  final String group;
  final List<CountRow> top;
  const GroupTop(this.group, this.top);

  static List<GroupTop> listFrom(Object? json) => ((json as List<dynamic>?) ?? [])
      .map((e) => GroupTop((e as Map<String, dynamic>)['group'] as String, CountRow.listFrom(e['top'])))
      .toList();
}

class TrendPoint {
  final String label;
  final int chatbot;
  final int checklist;
  const TrendPoint(this.label, this.chatbot, this.checklist);
  int get total => chatbot + checklist;
}

class ReportSummary {
  final ReportRange range;
  final DateTime generatedAt;
  final int registeredUsers;
  final int activeUsers;
  final int chatMessages;
  final int checklistSearches;
  final List<TrendPoint> trend;
  final List<CountRow> usersByDesignation;
  final List<CountRow> usersByAgeGroup;
  final List<CountRow> topConcerns;
  final List<GroupTop> concernsByDesignation;
  final List<GroupTop> concernsByAgeGroup;
  final List<CountRow> topWords;
  final List<CountRow> topHerbs;

  ReportSummary.fromJson(this.range, Map<String, dynamic> json)
      : generatedAt = DateTime.tryParse(json['generatedAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
        registeredUsers = (json['totals']['registeredUsers'] as num).toInt(),
        activeUsers = (json['totals']['activeUsers'] as num).toInt(),
        chatMessages = (json['totals']['chatMessages'] as num).toInt(),
        checklistSearches = (json['totals']['checklistSearches'] as num).toInt(),
        trend = ((json['trend'] as List<dynamic>?) ?? [])
            .map((e) => TrendPoint(e['label'] as String, (e['chatbot'] as num).toInt(), (e['checklist'] as num).toInt()))
            .toList(),
        usersByDesignation = CountRow.listFrom(json['usersByDesignation']),
        usersByAgeGroup = CountRow.listFrom(json['usersByAgeGroup']),
        topConcerns = CountRow.listFrom(json['topConcerns']),
        concernsByDesignation = GroupTop.listFrom(json['concernsByDesignation']),
        concernsByAgeGroup = GroupTop.listFrom(json['concernsByAgeGroup']),
        topWords = CountRow.listFrom(json['topWords']),
        topHerbs = CountRow.listFrom(json['topHerbs']);

  int get concernTotal => topConcerns.fold(0, (n, r) => n + r.count);
}

class ReportUser {
  final String name;
  final String email;
  final int? age;
  final String ageGroup;
  final String designation;
  final DateTime? createdAt;

  ReportUser.fromJson(Map<String, dynamic> j)
      : name = (j['name'] as String?) ?? '',
        email = (j['email'] as String?) ?? '',
        age = (j['age'] as num?)?.toInt(),
        ageGroup = (j['ageGroup'] as String?) ?? '',
        designation = (j['designation'] as String?) ?? 'Not specified',
        createdAt = DateTime.tryParse(j['createdAt'] as String? ?? '')?.toLocal();
}

class ReportLog {
  final String source;
  final String userName;
  final int? age;
  final String designation;
  final String message;
  final List<String> detectedSymptoms;
  final List<String> recommendedHerbs;
  final DateTime? createdAt;

  ReportLog.fromJson(Map<String, dynamic> j)
      : source = (j['source'] as String?) ?? 'chatbot',
        userName = (j['userName'] as String?) ?? '',
        age = (j['age'] as num?)?.toInt(),
        designation = (j['designation'] as String?) ?? 'Not specified',
        message = (j['message'] as String?) ?? '',
        detectedSymptoms = ((j['detectedSymptoms'] as List<dynamic>?) ?? []).map((e) => '$e').toList(),
        recommendedHerbs = ((j['recommendedHerbs'] as List<dynamic>?) ?? []).map((e) => '$e').toList(),
        createdAt = DateTime.tryParse(j['createdAt'] as String? ?? '')?.toLocal();
}

class ReportPage<T> {
  final List<T> items;
  final int total;
  final int? nextOffset;
  const ReportPage(this.items, this.total, this.nextOffset);
}

class ReportService {
  static const ageGroups = ['17 and below', '18-24', '25-34', '35-44', '45-59', '60 and above', 'Not specified'];
  static const designations = ['Student', 'Faculty', 'Herbalist', 'Farmer', 'Health worker', 'Others'];
  static const _timeout = Duration(seconds: 60);

  static String rangeKey(ReportRange r) =>
      {ReportRange.last7Days: '7d', ReportRange.last30Days: '30d', ReportRange.allTime: 'all'}[r]!;

  static String rangeLabel(ReportRange range) {
    switch (range) {
      case ReportRange.last7Days:
        return 'Last 7 days';
      case ReportRange.last30Days:
        return 'Last 30 days';
      case ReportRange.allTime:
        return 'All time';
    }
  }

  static Future<Map<String, String>> _headers() async {
    final token = await FirebaseAuthService.getIdToken();
    if (token == null) throw Exception('Not signed in');
    return {'Authorization': 'Bearer $token'};
  }

  static Future<http.Response> _get(String path, Map<String, String> query, {Duration? timeout}) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path').replace(queryParameters: query);
    final response = await http.get(uri, headers: await _headers()).timeout(timeout ?? _timeout);
    if (response.statusCode != 200) {
      throw Exception('Report request $path failed (${response.statusCode})');
    }
    return response;
  }

  static Future<ReportSummary> fetchSummary(ReportRange range) async {
    final response = await _get('/admin/report/summary', {'range': rangeKey(range)});
    return ReportSummary.fromJson(range, jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<ReportPage<ReportUser>> fetchUsers({
    String query = '',
    String designation = '',
    String ageGroup = '',
    int offset = 0,
  }) async {
    final response = await _get('/admin/report/users', {
      'q': query,
      'designation': designation,
      'ageGroup': ageGroup,
      'offset': '$offset',
    });
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ReportPage(
      (data['items'] as List<dynamic>).map((e) => ReportUser.fromJson(e as Map<String, dynamic>)).toList(),
      (data['total'] as num).toInt(),
      (data['nextOffset'] as num?)?.toInt(),
    );
  }

  static Future<ReportPage<ReportLog>> fetchLogs({
    required ReportRange range,
    String query = '',
    String source = '',
    String designation = '',
    int offset = 0,
  }) async {
    final response = await _get('/admin/report/logs', {
      'range': rangeKey(range),
      'q': query,
      'source': source,
      'designation': designation,
      'offset': '$offset',
    });
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ReportPage(
      (data['items'] as List<dynamic>).map((e) => ReportLog.fromJson(e as Map<String, dynamic>)).toList(),
      (data['total'] as num).toInt(),
      (data['nextOffset'] as num?)?.toInt(),
    );
  }

  /// Full data (Summary, Users, Chatbot Logs, Checklist Logs) as .xlsx. The
  /// server records the export in the admin activity log.
  static Future<Uint8List> downloadExcel(ReportRange range) async {
    final response = await _get('/admin/report/export.xlsx', {'range': rangeKey(range)},
        timeout: const Duration(seconds: 120));
    debugPrint('Excel export: ${response.bodyBytes.length} bytes');
    return response.bodyBytes;
  }

  static String formatDate(DateTime? d, {bool withTime = false}) {
    if (d == null) return '-';
    String two(int n) => n.toString().padLeft(2, '0');
    final date = '${d.year}-${two(d.month)}-${two(d.day)}';
    return withTime ? '$date ${two(d.hour)}:${two(d.minute)}' : date;
  }

  /// The built-in PDF fonts only cover Latin-1; replace anything else.
  static String _pdfSafe(String s) => s.replaceAll(RegExp(r'[^ -~ -ÿ\n]'), '?');

  /// A short summary PDF (a few pages, whatever the number of users). The
  /// full user list and activity log are in the Excel export.
  static Future<Uint8List> buildPdf(ReportSummary r, {required String generatedBy}) async {
    final doc = pw.Document(title: 'HerbAI Usage Report', author: 'HerbAI');
    final green = PdfColor.fromHex('#2E7D32');
    final headerStyle = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white);
    const cellStyle = pw.TextStyle(fontSize: 10);

    pw.Widget heading(String text) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
          child: pw.Text(text, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: green)),
        );

    pw.Widget countTable(String label, List<CountRow> rows, int total) {
      if (rows.isEmpty) return pw.Text('No data for this period.', style: cellStyle);
      return pw.TableHelper.fromTextArray(
        headers: [label, 'Count', 'Percent'],
        data: [
          for (final row in rows)
            [_pdfSafe(row.label), '${row.count}', total == 0 ? '-' : '${(row.count * 100 / total).toStringAsFixed(1)}%'],
        ],
        headerStyle: headerStyle,
        headerDecoration: pw.BoxDecoration(color: green),
        cellStyle: cellStyle,
        cellAlignments: {1: pw.Alignment.centerRight, 2: pw.Alignment.centerRight},
      );
    }

    pw.Widget groupTable(String label, List<GroupTop> groups) {
      if (groups.isEmpty) return pw.Text('No data for this period.', style: cellStyle);
      return pw.TableHelper.fromTextArray(
        headers: [label, 'Top symptom concerns'],
        data: [
          for (final g in groups) [_pdfSafe(g.group), g.top.map((e) => '${e.label} (${e.count})').join(', ')],
        ],
        headerStyle: headerStyle,
        headerDecoration: pw.BoxDecoration(color: green),
        cellStyle: cellStyle,
        columnWidths: {0: const pw.FlexColumnWidth(1), 1: const pw.FlexColumnWidth(3)},
      );
    }

    final activeTrend = r.trend.where((t) => t.total > 0).toList();

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      ),
      build: (context) => [
        pw.Text('HerbAI Usage Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: green)),
        pw.SizedBox(height: 4),
        pw.Text('AI-Driven Integration of Ethnobotanical Knowledge: A Mobile System for Local Herbal Plant Recommendations',
            style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 8),
        pw.Text('Period: ${rangeLabel(r.range)}', style: const pw.TextStyle(fontSize: 10)),
        pw.Text('Generated: ${formatDate(r.generatedAt, withTime: true)} by ${_pdfSafe(generatedBy)}',
            style: const pw.TextStyle(fontSize: 10)),
        heading('Summary'),
        pw.TableHelper.fromTextArray(
          headers: ['Measure', 'Value'],
          data: [
            ['Registered users (all time)', '${r.registeredUsers}'],
            ['Active users in period (chatbot or checklist)', '${r.activeUsers}'],
            ['Chatbot messages in period', '${r.chatMessages}'],
            ['Checklist searches in period', '${r.checklistSearches}'],
          ],
          headerStyle: headerStyle,
          headerDecoration: pw.BoxDecoration(color: green),
          cellStyle: cellStyle,
        ),
        heading('1. Who uses the system: users by designation'),
        countTable('Designation', r.usersByDesignation, r.registeredUsers),
        heading('2. Who uses the system: users by age group'),
        countTable('Age group', r.usersByAgeGroup, r.registeredUsers),
        heading('3. Most common symptom concerns (chatbot and checklist)'),
        countTable('Symptom', r.topConcerns, r.concernTotal),
        heading('4. Symptom concerns by designation'),
        groupTable('Designation', r.concernsByDesignation),
        heading('5. Symptom concerns by age group'),
        groupTable('Age group', r.concernsByAgeGroup),
        heading('6. Most frequent words typed in the chatbot'),
        countTable('Word', r.topWords, r.chatMessages),
        heading('7. Most recommended herbs'),
        countTable('Herb', r.topHerbs, r.topHerbs.fold(0, (n, e) => n + e.count)),
        heading('8. Activity over time'),
        activeTrend.isEmpty
            ? pw.Text('No activity in this period.', style: cellStyle)
            : pw.TableHelper.fromTextArray(
                headers: [r.range == ReportRange.allTime ? 'Month' : 'Day', 'Chatbot messages', 'Checklist searches'],
                data: [for (final t in activeTrend) [t.label, '${t.chatbot}', '${t.checklist}']],
                headerStyle: headerStyle,
                headerDecoration: pw.BoxDecoration(color: green),
                cellStyle: cellStyle,
                cellAlignments: {1: pw.Alignment.centerRight, 2: pw.Alignment.centerRight},
              ),
        pw.SizedBox(height: 12),
        pw.Text(
          'The complete list of users and every chatbot/checklist record are in the Excel export '
          '(Usage Reports > Excel). Symptom concerns are the symptoms detected in chatbot messages plus those '
          'picked in the Select Your Symptoms checklist. Herb recommendations come from the HerbAI XGBoost model. '
          'For educational and research use only.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
      ],
    ));
    return doc.save();
  }
}
