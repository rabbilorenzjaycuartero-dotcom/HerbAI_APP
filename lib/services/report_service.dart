import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Admin usage reports (panel revision): who uses HerbAI (age, designation)
/// and what they ask the chatbot (top symptom concerns, typed words).
/// Data: users/{uid} profiles and chat_logs written by the /chat endpoint.

enum ReportRange { last7Days, last30Days, allTime }

class ReportUser {
  final String name;
  final int? age;
  final String designation;
  final DateTime? createdAt;
  const ReportUser({required this.name, this.age, required this.designation, this.createdAt});
}

class ReportLog {
  final DateTime? createdAt;
  final String uid;
  final String userName;
  final int? age;
  final String designation;
  final String message;
  final List<String> detectedSymptoms;
  final List<String> recommendedHerbs;
  // 'chatbot' or 'checklist' (Select Your Symptoms). Logs written before
  // this field existed are all chatbot turns.
  final String source;
  const ReportLog({
    this.createdAt,
    required this.uid,
    required this.userName,
    this.age,
    required this.designation,
    required this.message,
    required this.detectedSymptoms,
    required this.recommendedHerbs,
    this.source = 'chatbot',
  });
}

class UsageReport {
  final ReportRange range;
  final DateTime generatedAt;
  final List<ReportUser> users;
  final List<ReportLog> logs;

  UsageReport({required this.range, required this.generatedAt, required this.users, required this.logs});

  static const ageGroups = ['17 and below', '18-24', '25-34', '35-44', '45-59', '60 and above', 'Not specified'];

  static String ageGroup(int? age) {
    if (age == null) return 'Not specified';
    if (age <= 17) return '17 and below';
    if (age <= 24) return '18-24';
    if (age <= 34) return '25-34';
    if (age <= 44) return '35-44';
    if (age <= 59) return '45-59';
    return '60 and above';
  }

  static String designationGroup(String designation) =>
      designation.startsWith('Others') ? 'Others' : designation;

  /// Ordered (label, count) pairs, largest first.
  static List<MapEntry<String, int>> _sorted(Map<String, int> counts, {int? limit}) {
    final list = counts.entries.toList()
      ..sort((a, b) => b.value != a.value ? b.value.compareTo(a.value) : a.key.compareTo(b.key));
    return limit == null ? list : list.take(limit).toList();
  }

  Map<String, int> _count(Iterable<String> items) {
    final out = <String, int>{};
    for (final item in items) {
      out[item] = (out[item] ?? 0) + 1;
    }
    return out;
  }

  List<MapEntry<String, int>> get usersByDesignation =>
      _sorted(_count(users.map((u) => designationGroup(u.designation))));

  List<MapEntry<String, int>> get usersByAgeGroup {
    final counts = _count(users.map((u) => ageGroup(u.age)));
    return [for (final g in ageGroups) if (counts.containsKey(g)) MapEntry(g, counts[g]!)];
  }

  List<ReportLog> get messageLogs => logs.where((l) => l.message.isNotEmpty).toList();

  int get activeUsers => logs.map((l) => l.uid).toSet().length;

  List<ReportLog> get checklistLogs => logs.where((l) => l.source == 'checklist').toList();
  List<ReportLog> get chatbotLogs => logs.where((l) => l.source != 'checklist').toList();

  List<MapEntry<String, int>> topConcerns({int limit = 10}) =>
      _sorted(_count(logs.expand((l) => l.detectedSymptoms)), limit: limit);

  List<MapEntry<String, int>> topHerbs({int limit = 10}) =>
      _sorted(_count(logs.expand((l) => l.recommendedHerbs)), limit: limit);

  /// Top concerns per group (designation or age group).
  Map<String, List<MapEntry<String, int>>> concernsBy(String Function(ReportLog) group, {int limit = 3}) {
    final buckets = <String, Map<String, int>>{};
    for (final log in logs) {
      final bucket = buckets.putIfAbsent(group(log), () => {});
      for (final s in log.detectedSymptoms) {
        bucket[s] = (bucket[s] ?? 0) + 1;
      }
    }
    final out = <String, List<MapEntry<String, int>>>{};
    for (final entry in buckets.entries) {
      if (entry.value.isNotEmpty) out[entry.key] = _sorted(entry.value, limit: limit);
    }
    return out;
  }

  Map<String, List<MapEntry<String, int>>> get concernsByDesignation =>
      concernsBy((l) => designationGroup(l.designation));

  Map<String, List<MapEntry<String, int>>> get concernsByAgeGroup => concernsBy((l) => ageGroup(l.age));

  static const _stopwords = {
    // English
    'i', 'im', "i'm", 'ive', 'a', 'an', 'the', 'and', 'or', 'my', 'is', 'am', 'are', 'was', 'me', 'of', 'to',
    'in', 'on', 'for', 'with', 'it', 'also', 'so', 'very', 'really', 'feel', 'feeling', 'been', 'have', 'has',
    'had', 'since', 'what', 'how', 'can', 'do', 'does', 'please', 'some', 'that', 'this', 'there', 'be', 'but',
    'just', 'today', 'now', 'lately', 'little', 'bit', 'any', 'herb', 'herbs', 'good', 'help', 'need', 'want',
    // Bisaya
    'naa', 'ko', 'koy', 'kog', 'ako', 'akong', 'ang', 'sa', 'ug', 'og', 'nga', 'man', 'kaayo', 'karon', 'unsa',
    'unsaon', 'pa', 'na', 'lang', 'ra', 'kay', 'mao', 'kini', 'ni', 'ana', 'gyud', 'jud', 'wala', 'dili', 'nako',
    'nimo', 'pod', 'pud', 'sad', 'usab', 'unta', 'diay', 'bitaw', 'si', 'ka', 'mo', 'ta', 'ba', 'tungod', 'kung',
    'para', 'maayo', 'tambal', 'gibati', 'akoa', 'nag', 'naay', 'kahibalo',
    // Tagalog
    'may', 'ng', 'at', 'mga', 'ay', 'po', 'din', 'rin', 'ito', 'yung', 'kasi', 'akin',
    'ano', 'nang', 'pero', 'lagi', 'sobra', 'masyado', 'ngayon', 'yun', 'gamot', 'mabuti',
  };

  List<MapEntry<String, int>> topWords({int limit = 15}) {
    final words = messageLogs
        .expand((l) => l.message.toLowerCase().split(RegExp(r"[^a-zA-ZÀ-ÿñÑ'\-]+")))
        .map((w) => w.replaceAll(RegExp(r"^['\-]+|['\-]+$"), ''))
        .where((w) => w.length >= 3 && !_stopwords.contains(w));
    return _sorted(_count(words), limit: limit);
  }
}

class ReportService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static const _maxLogs = 2000;

  static DateTime? rangeStart(ReportRange range, DateTime now) {
    switch (range) {
      case ReportRange.last7Days:
        return now.subtract(const Duration(days: 7));
      case ReportRange.last30Days:
        return now.subtract(const Duration(days: 30));
      case ReportRange.allTime:
        return null;
    }
  }

  static Future<UsageReport> load(ReportRange range) async {
    final now = DateTime.now();
    final start = rangeStart(range, now);

    final usersSnap = await _db.collection('users').get();
    final users = usersSnap.docs.map((d) {
      final data = d.data();
      final designation = (data['designation'] as String?) ?? 'Not specified';
      final other = (data['designationOther'] as String?) ?? '';
      return ReportUser(
        name: (data['name'] as String?) ?? '',
        age: (data['age'] as num?)?.toInt(),
        designation: designation == 'Others' && other.isNotEmpty ? 'Others ($other)' : designation,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      );
    }).toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

    Query<Map<String, dynamic>> query = _db.collection('chat_logs');
    if (start != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start));
    }
    final logsSnap = await query.orderBy('createdAt', descending: true).limit(_maxLogs).get();
    final logs = logsSnap.docs.map((d) {
      final data = d.data();
      List<String> strings(Object? v) => ((v as List<dynamic>?) ?? []).map((e) => '$e').toList();
      return ReportLog(
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        uid: (data['uid'] as String?) ?? '',
        userName: (data['userName'] as String?) ?? '',
        age: (data['age'] as num?)?.toInt(),
        designation: (data['designation'] as String?) ?? 'Not specified',
        message: (data['message'] as String?) ?? '',
        detectedSymptoms: strings(data['detectedSymptoms']),
        recommendedHerbs: strings(data['recommendedHerbs']),
        source: (data['source'] as String?) ?? 'chatbot',
      );
    }).toList();

    return UsageReport(range: range, generatedAt: now, users: users, logs: logs);
  }

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

  static String formatDate(DateTime? d, {bool withTime = false}) {
    if (d == null) return '-';
    String two(int n) => n.toString().padLeft(2, '0');
    final date = '${d.year}-${two(d.month)}-${two(d.day)}';
    return withTime ? '$date ${two(d.hour)}:${two(d.minute)}' : date;
  }

  /// The built-in PDF fonts only cover Latin-1; replace anything else
  /// (emoji, symbols) so user-typed text never breaks the export.
  static String _pdfSafe(String s) =>
      s.replaceAll(RegExp(r'[^ -~ -ÿ\n]'), '?');

  static Future<Uint8List> buildPdf(UsageReport report, {required String generatedBy}) async {
    final doc = pw.Document(title: 'HerbAI Usage Report', author: 'HerbAI');
    final green = PdfColor.fromHex('#2E7D32');

    pw.Widget heading(String text) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
          child: pw.Text(text, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: green)),
        );

    pw.Widget countTable(String label, List<MapEntry<String, int>> rows, int total) {
      if (rows.isEmpty) return pw.Text('No data for this period.', style: const pw.TextStyle(fontSize: 10));
      return pw.TableHelper.fromTextArray(
        headers: [label, 'Count', 'Percent'],
        data: [
          for (final r in rows)
            [_pdfSafe(r.key), '${r.value}', total == 0 ? '-' : '${(r.value * 100 / total).toStringAsFixed(1)}%'],
        ],
        headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        headerDecoration: pw.BoxDecoration(color: green),
        cellStyle: const pw.TextStyle(fontSize: 10),
        cellAlignments: {1: pw.Alignment.centerRight, 2: pw.Alignment.centerRight},
      );
    }

    pw.Widget groupTable(String label, Map<String, List<MapEntry<String, int>>> groups) {
      if (groups.isEmpty) return pw.Text('No data for this period.', style: const pw.TextStyle(fontSize: 10));
      return pw.TableHelper.fromTextArray(
        headers: [label, 'Top symptom concerns'],
        data: [
          for (final g in groups.entries)
            [_pdfSafe(g.key), g.value.map((e) => '${e.key} (${e.value})').join(', ')],
        ],
        headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        headerDecoration: pw.BoxDecoration(color: green),
        cellStyle: const pw.TextStyle(fontSize: 10),
        columnWidths: {0: const pw.FlexColumnWidth(1), 1: const pw.FlexColumnWidth(3)},
      );
    }

    final concerns = report.topConcerns();
    final concernTotal = report.logs.fold<int>(0, (n, l) => n + l.detectedSymptoms.length);
    final recent = report.messageLogs.take(100).toList();

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (context) => context.pageNumber == 1
          ? pw.SizedBox()
          : pw.Text('HerbAI Usage Report', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
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
        pw.Text('Chatbot activity period: ${rangeLabel(report.range)}', style: const pw.TextStyle(fontSize: 10)),
        pw.Text('Generated: ${formatDate(report.generatedAt, withTime: true)} by ${_pdfSafe(generatedBy)}',
            style: const pw.TextStyle(fontSize: 10)),
        heading('Summary'),
        pw.TableHelper.fromTextArray(
          headers: ['Measure', 'Value'],
          data: [
            ['Registered users (all time)', '${report.users.length}'],
            ['Chatbot messages in period', '${report.messageLogs.length}'],
            ['Checklist searches in period (Select Your Symptoms)', '${report.checklistLogs.length}'],
            ['Users who used the system in period (chatbot or checklist)', '${report.activeUsers}'],
          ],
          headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: pw.BoxDecoration(color: green),
          cellStyle: const pw.TextStyle(fontSize: 10),
        ),
        heading('1. Who uses the system: users by designation'),
        countTable('Designation', report.usersByDesignation, report.users.length),
        heading('2. Who uses the system: users by age group'),
        countTable('Age group', report.usersByAgeGroup, report.users.length),
        heading('3. Most common symptom concerns (chatbot and checklist)'),
        countTable('Symptom', concerns, concernTotal),
        heading('4. Symptom concerns by designation'),
        groupTable('Designation', report.concernsByDesignation),
        heading('5. Symptom concerns by age group'),
        groupTable('Age group', report.concernsByAgeGroup),
        heading('6. Most frequent words typed in the chatbot'),
        countTable('Word', report.topWords(), report.messageLogs.length),
        heading('7. Most recommended herbs'),
        countTable('Herb', report.topHerbs(), report.logs.where((l) => l.recommendedHerbs.isNotEmpty).length),
        heading('8. Registered users'),
        pw.TableHelper.fromTextArray(
          headers: ['Name', 'Age', 'Designation', 'Registered'],
          data: [
            for (final u in report.users)
              [_pdfSafe(u.name), u.age?.toString() ?? '-', _pdfSafe(u.designation), formatDate(u.createdAt)],
          ],
          headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: pw.BoxDecoration(color: green),
          cellStyle: const pw.TextStyle(fontSize: 9),
        ),
        heading('9. Chatbot activity log (latest ${recent.length})'),
        pw.TableHelper.fromTextArray(
          headers: ['Date', 'User', 'Designation', 'Typed message', 'Detected symptoms'],
          data: [
            for (final l in recent)
              [
                formatDate(l.createdAt, withTime: true),
                _pdfSafe(l.userName),
                _pdfSafe(l.designation),
                _pdfSafe(l.message),
                l.detectedSymptoms.join(', '),
              ],
          ],
          headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: pw.BoxDecoration(color: green),
          cellStyle: const pw.TextStyle(fontSize: 8),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.3),
            1: const pw.FlexColumnWidth(1.3),
            2: const pw.FlexColumnWidth(1.2),
            3: const pw.FlexColumnWidth(3),
            4: const pw.FlexColumnWidth(1.8),
          },
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'Note: Symptom concerns are the symptoms the HerbAI chatbot detected in users\' messages plus the symptoms '
          'users picked in the Select Your Symptoms checklist. '
          'Herb recommendations come from the HerbAI XGBoost model. For educational and research use only.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
      ],
    ));
    return doc.save();
  }
}
