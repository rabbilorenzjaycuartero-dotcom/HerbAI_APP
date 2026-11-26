import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// The demographic options the panel asked the reports to group users by.
/// Stored in Firestore as these exact English values; translated only for
/// display.
const List<String> designationOptions = [
  'Student',
  'Faculty',
  'Herbalist',
  'Farmer',
  'Health worker',
  'Others',
];

class UserProfile {
  final String name;
  final String email;
  final int? age;
  final String? designation;
  final String? designationOther;

  const UserProfile({
    required this.name,
    required this.email,
    this.age,
    this.designation,
    this.designationOther,
  });

  bool get isComplete => age != null && designation != null && designation!.isNotEmpty;

  /// "Others (Nurse)" style label for reports.
  String get designationLabel {
    if (designation == null || designation!.isEmpty) return 'Not specified';
    if (designation == 'Others' && (designationOther ?? '').isNotEmpty) {
      return 'Others ($designationOther)';
    }
    return designation!;
  }

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      age: (data['age'] as num?)?.toInt(),
      designation: data['designation'] as String?,
      designationOther: data['designationOther'] as String?,
    );
  }
}

/// users/{uid} profile documents (name, email, age, designation) and the
/// admins/{uid} marker that unlocks the Reports screen.
class UserProfileService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static Future<UserProfile?> getProfile(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    return UserProfile.fromMap(snap.data() ?? {});
  }

  static Future<void> saveProfile({
    required String uid,
    required String name,
    required String email,
    required int age,
    required String designation,
    String? designationOther,
  }) async {
    final ref = _db.collection('users').doc(uid);
    final exists = (await ref.get()).exists;
    await ref.set({
      'name': name,
      'email': email,
      'age': age,
      'designation': designation,
      'designationOther': designation == 'Others' ? designationOther : null,
      'updatedAt': FieldValue.serverTimestamp(),
      if (!exists) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<bool> isAdmin(String uid) async {
    try {
      return (await _db.collection('admins').doc(uid).get()).exists;
    } catch (e) {
      debugPrint('Admin check failed: $e');
      return false;
    }
  }
}
