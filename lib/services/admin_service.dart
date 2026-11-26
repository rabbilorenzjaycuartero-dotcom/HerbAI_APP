import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/app_constants.dart';
import 'firebase_auth_service.dart';

const int maxAdmins = 3;

class AdminAccount {
  final String uid;
  final String email;
  final String name;
  final bool isMain;
  final String addedByEmail;
  final DateTime? createdAt;

  const AdminAccount({
    required this.uid,
    required this.email,
    required this.name,
    required this.isMain,
    required this.addedByEmail,
    this.createdAt,
  });
}

class AdminLogEntry {
  final String action;
  final String actorEmail;
  final String actorName;
  final Map<String, dynamic> details;
  final DateTime? createdAt;

  const AdminLogEntry({
    required this.action,
    required this.actorEmail,
    required this.actorName,
    required this.details,
    this.createdAt,
  });
}

/// Admin management (max 3 admins, main admin protected) and the admin
/// activity log. Reads come straight from Firestore (admins only, see
/// firestore.rules); every change and log entry goes through the server so
/// it is always attributed to the real signed-in admin.
class AdminService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static Uri _uri(String path) => Uri.parse('${AppConstants.apiBaseUrl}$path');
  static const _timeout = Duration(seconds: 30);

  static Future<List<AdminAccount>> listAdmins() async {
    final snap = await _db.collection('admins').get();
    final admins = snap.docs.map((d) {
      final data = d.data();
      return AdminAccount(
        uid: d.id,
        email: (data['email'] as String?) ?? '',
        name: (data['name'] as String?) ?? '',
        isMain: data['isMain'] == true,
        addedByEmail: (data['addedByEmail'] as String?) ?? '',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      );
    }).toList()
      ..sort((a, b) {
        if (a.isMain != b.isMain) return a.isMain ? -1 : 1;
        return (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0));
      });
    return admins;
  }

  static Future<List<AdminLogEntry>> activityLog({int limit = 300}) async {
    final snap = await _db
        .collection('admin_logs')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      return AdminLogEntry(
        action: (data['action'] as String?) ?? '',
        actorEmail: (data['actorEmail'] as String?) ?? '',
        actorName: (data['actorName'] as String?) ?? '',
        details: (data['details'] as Map<String, dynamic>?) ?? const {},
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      );
    }).toList();
  }

  static Future<Map<String, String>> _headers() async {
    final token = await FirebaseAuthService.getIdToken();
    if (token == null) throw Exception('Not signed in');
    return {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  }

  /// Creates a new account and makes it an admin. Returns null on success or
  /// a user-facing error message.
  static Future<String?> createAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            _uri('/admin/admins'),
            headers: await _headers(),
            body: jsonEncode({'name': name, 'email': email, 'password': password}),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['error'] as String?) ?? 'Could not add the admin.';
    } catch (e) {
      debugPrint('createAdmin failed: $e');
      return 'Could not reach the server. Please try again.';
    }
  }

  /// Removes admin rights from [uid]. Returns null on success or an error.
  static Future<String?> removeAdmin(String uid) async {
    try {
      final response =
          await http.delete(_uri('/admin/admins/$uid'), headers: await _headers()).timeout(_timeout);
      if (response.statusCode == 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['error'] as String?) ?? 'Could not remove the admin.';
    } catch (e) {
      debugPrint('removeAdmin failed: $e');
      return 'Could not reach the server. Please try again.';
    }
  }

  /// Records "open_reports" / "export_pdf" in the admin activity log.
  /// Fire-and-forget: never throws, never blocks the screen.
  static Future<void> log(String action, {Map<String, String> details = const {}}) async {
    try {
      await http
          .post(
            _uri('/admin/log'),
            headers: await _headers(),
            body: jsonEncode({'action': action, 'details': details}),
          )
          .timeout(_timeout);
    } catch (e) {
      debugPrint('Admin log ($action) failed: $e');
    }
  }
}
