import 'package:flutter/foundation.dart';
import '../services/firebase_auth_service.dart';
import '../services/user_profile_service.dart';

/// App-wide profile state (age, designation, admin flag). A global
/// singleton rather than a Provider because the go_router redirect -- which
/// sends users without age/designation to /complete-profile and guards
/// /admin/reports -- runs outside the widget tree.
class UserProfileStore extends ChangeNotifier {
  String? _uid;
  UserProfile? _profile;
  bool _loaded = false;
  bool _isAdmin = false;

  UserProfile? get profile => _profile;
  bool get isAdmin => _isAdmin;

  /// True only once we KNOW the signed-in user has no complete profile --
  /// never while still loading, so the redirect doesn't flash.
  bool get needsProfile => _uid != null && _loaded && !(_profile?.isComplete ?? false);

  Future<void> loadFor(String? uid) async {
    if (uid == _uid && _loaded) return;
    _uid = uid;
    _profile = null;
    _isAdmin = false;
    _loaded = false;
    notifyListeners();
    if (uid == null) return;
    try {
      final results = await Future.wait([
        UserProfileService.getProfile(uid),
        UserProfileService.isAdmin(uid),
      ]);
      if (_uid != uid) return; // signed out / switched while loading
      _profile = results[0] as UserProfile?;
      _isAdmin = results[1] as bool;
      _loaded = true;
    } catch (e) {
      // Leave _loaded false: a network error must not lock the user out
      // behind the Complete Profile screen.
      debugPrint('Failed to load user profile: $e');
    }
    notifyListeners();
  }

  Future<void> save({
    required String name,
    required String email,
    required int age,
    required String designation,
    String? designationOther,
  }) async {
    final uid = FirebaseAuthService.currentUser?.uid ?? _uid;
    if (uid == null) throw StateError('Not signed in');
    await UserProfileService.saveProfile(
      uid: uid,
      name: name,
      email: email,
      age: age,
      designation: designation,
      designationOther: designationOther,
    );
    _uid = uid;
    _profile = UserProfile(
      name: name,
      email: email,
      age: age,
      designation: designation,
      designationOther: designation == 'Others' ? designationOther : null,
    );
    _loaded = true;
    notifyListeners();
  }
}

final UserProfileStore userProfileStore = UserProfileStore();
