import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthUser {
  const AuthUser({
    this.email,
    this.displayName,
    this.emailVerified = false,
    User? firebaseUser,
  }) : _firebaseUser = firebaseUser;

  final String? email;
  final String? displayName;
  final bool emailVerified;
  final User? _firebaseUser;

  String? get uid => _firebaseUser?.uid;

  static AuthUser fromFirebaseUser(User user) {
    return AuthUser(
      email: user.email,
      displayName: user.displayName,
      emailVerified: user.emailVerified,
      firebaseUser: user,
    );
  }

  Future<void> reload() async {
    await _firebaseUser?.reload();
  }
}

class AuthUnavailableException implements Exception {
  const AuthUnavailableException([this.message = 'Authentication is currently unavailable until Firebase is reconnected.']);

  final String message;

  @override
  String toString() => message;
}

/// Carries a user-facing message translated from a lower-level auth error.
/// Unlike a plain `Exception(message)`, [toString] returns the message
/// as-is instead of prefixing it with "Exception: ", since it is shown
/// directly in UI (SnackBars) via `e.toString()` or [getErrorMessage].
class AuthFailureException implements Exception {
  const AuthFailureException(this.message, {this.code});

  final String message;
  // The original FirebaseAuthException.code, preserved so callers (e.g.
  // the Login screen telling "wrong email" apart from "wrong password")
  // can still branch on it even though the exception itself has already
  // been converted to a friendly message by the time it's thrown here.
  final String? code;

  @override
  String toString() => message;
}

class FirebaseAuthService {
  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static AuthUser? _currentUser;

  static AuthUser? get currentUser => _currentUser;

  static Stream<AuthUser?> authStateChanges() {
    debugPrint('Setting up auth state changes stream');
    return _auth.authStateChanges().map((user) {
      debugPrint('Auth state changed: ${user?.email ?? 'signed out'}');
      _currentUser = user == null ? null : AuthUser.fromFirebaseUser(user);
      return _currentUser;
    }).handleError((Object error, StackTrace stackTrace) {
      debugPrint('Auth stream error: $error');
      debugPrintStack(stackTrace: stackTrace);
    });
  }

  static Future<void> syncCurrentUser() async {
    debugPrint('Syncing current user...');
    final user = _auth.currentUser;
    if (user != null) {
      debugPrint('Current user found: ${user.email}, verified: ${user.emailVerified}');
    } else {
      debugPrint('No current user (signed out)');
    }
    _currentUser = user == null ? null : AuthUser.fromFirebaseUser(user);
    debugPrint('Auth state synced: ${user?.email ?? 'signed out'}');
  }

  /// Reloads the Firebase user and refreshes the cached route-guard state.
  static Future<AuthUser?> refreshCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      _currentUser = null;
      return null;
    }

    await user.reload();
    final refreshedUser = _auth.currentUser;
    _currentUser = refreshedUser == null
        ? null
        : AuthUser.fromFirebaseUser(refreshedUser);
    return _currentUser;
  }

  static Future<AuthUser> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    debugPrint('========== REGISTER START ==========');
    debugPrint('Register requested for $email');
    debugPrint('Name: $name');
    try {
      debugPrint('Calling createUserWithEmailAndPassword...');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('createUserWithEmailAndPassword completed');

      final user = credential.user;
      if (user == null) {
        debugPrint('ERROR: User is null after creation');
        throw const AuthUnavailableException('Account creation failed.');
      }
      debugPrint('User created with UID: ${user.uid}');

      debugPrint('Updating display name to: $name');
      await user.updateDisplayName(name);
      debugPrint('Display name updated successfully');

      await refreshCurrentUser();
      debugPrint('========== REGISTER SUCCESS ==========');
      debugPrint('Register successful for $email');
      return _currentUser!;
    } on FirebaseAuthException catch (error) {
      debugPrint('========== REGISTER FAILED ==========');
      debugPrint('Exception code: ${error.code}');
      debugPrint('Exception message: ${error.message}');
      debugPrint('Stack trace:');
      debugPrintStack(stackTrace: StackTrace.current);
      throw AuthFailureException(getErrorMessage(error), code: error.code);
    } catch (error, stackTrace) {
      debugPrint('========== REGISTER ERROR ==========');
      debugPrint('Unexpected error: $error');
      debugPrint('Error type: ${error.runtimeType}');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<AuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    debugPrint('========== LOGIN START ==========');
    debugPrint('Login requested for $email');
    try {
      debugPrint('Calling signInWithEmailAndPassword...');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('signInWithEmailAndPassword completed');

      final user = credential.user;
      if (user == null) {
        debugPrint('ERROR: User is null after sign in');
        throw const AuthUnavailableException('Unable to sign in.');
      }
      debugPrint('User signed in with UID: ${user.uid}');
      debugPrint('Email verified: ${user.emailVerified}');

      await refreshCurrentUser();
      debugPrint('========== LOGIN SUCCESS ==========');
      debugPrint('Login successful for $email');
      return _currentUser!;
    } on FirebaseAuthException catch (error) {
      debugPrint('========== LOGIN FAILED ==========');
      debugPrint('Exception code: ${error.code}');
      debugPrint('Exception message: ${error.message}');
      debugPrint('Stack trace:');
      debugPrintStack(stackTrace: StackTrace.current);
      throw AuthFailureException(getErrorMessage(error), code: error.code);
    } catch (error, stackTrace) {
      debugPrint('========== LOGIN ERROR ==========');
      debugPrint('Unexpected error: $error');
      debugPrint('Error type: ${error.runtimeType}');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  /// The signed-in user's Firebase ID token, sent as a Bearer token so the
  /// Flask backend's /send-verification-code and /verify-email-code routes
  /// can verify which account is actually calling rather than trusting a
  /// client-supplied uid/email.
  static Future<String?> getIdToken() => _auth.currentUser?.getIdToken() ?? Future.value(null);

  static Future<void> sendPasswordResetEmail(String email) async {
    debugPrint('========== PASSWORD RESET START ==========');
    debugPrint('Password reset requested for $email');
    try {
      debugPrint('Calling sendPasswordResetEmail()...');
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('Password reset email sent successfully to $email');
      debugPrint('========== PASSWORD RESET SUCCESS ==========');
    } on FirebaseAuthException catch (error) {
      debugPrint('========== PASSWORD RESET FAILED ==========');
      debugPrint('Exception code: ${error.code}');
      debugPrint('Exception message: ${error.message}');
      debugPrintStack(stackTrace: StackTrace.current);
      throw AuthFailureException(getErrorMessage(error), code: error.code);
    } catch (error, stackTrace) {
      debugPrint('========== PASSWORD RESET ERROR ==========');
      debugPrint('Unexpected error: $error');
      debugPrint('Error type: ${error.runtimeType}');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<void> signOut() async {
    debugPrint('========== LOGOUT START ==========');
    final user = _auth.currentUser;
    debugPrint('Logout requested for ${user?.email ?? 'null'}');
    await _auth.signOut();
    _currentUser = null;
    debugPrint('========== LOGOUT COMPLETE ==========');
    debugPrint('Logout completed. User signed out.');
  }

  static String getErrorMessage(Object error) {
    if (error is AuthUnavailableException) {
      return error.message;
    }
    if (error is AuthFailureException) {
      return error.message;
    }
    if (error is FirebaseAuthException) {
      // Normalized because the exact code string varies by platform --
      // Android's native SDK returns e.g. "ERROR_INVALID_CREDENTIAL" where
      // iOS/other platforms return the lowercase-hyphenated
      // "invalid-credential" these cases were written against. Without
      // this, every case below silently falls through to the raw/ugly
      // default message on Android.
      var code = error.code.toLowerCase().replaceAll('_', '-');
      if (code.startsWith('error-')) {
        code = code.substring('error-'.length);
      }
      switch (code) {
        case 'email-already-in-use':
          return 'This email is already in use.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'operation-not-allowed':
          return 'Email/password sign-in is not enabled for this project.';
        case 'weak-password':
          return 'Please choose a stronger password.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
          return 'No account found for that email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'requires-recent-login':
          return 'Please sign in again to continue.';
        default:
          return error.message ?? 'Something went wrong. Please try again.';
      }
    }
    if (error is Exception) {
      return error.toString();
    }
    return 'Something went wrong. Please try again.';
  }

  /// The raw Firebase error code (e.g. 'invalid-credential', 'wrong-password'),
  /// or null for anything else. Lets callers branch on specific codes
  /// without importing package:firebase_auth directly. Checks
  /// AuthFailureException too, since signInWithEmailAndPassword/etc. always
  /// convert the real FirebaseAuthException into one of those before it
  /// reaches calling screens -- the original code only survives via the
  /// field added there for exactly this purpose.
  static String? errorCode(Object error) {
    if (error is FirebaseAuthException) return error.code;
    if (error is AuthFailureException) return error.code;
    return null;
  }
}
