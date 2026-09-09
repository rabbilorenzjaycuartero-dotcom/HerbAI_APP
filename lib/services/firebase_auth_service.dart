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

  Future<void> sendEmailVerification() async {
    await _firebaseUser?.sendEmailVerification();
  }
}

class AuthUnavailableException implements Exception {
  const AuthUnavailableException([this.message = 'Authentication is currently unavailable until Firebase is reconnected.']);

  final String message;

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

      debugPrint('Sending email verification...');
      await user.sendEmailVerification();
      debugPrint('Email verification sent successfully');

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
      throw Exception(getErrorMessage(error));
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
      throw Exception(getErrorMessage(error));
    } catch (error, stackTrace) {
      debugPrint('========== LOGIN ERROR ==========');
      debugPrint('Unexpected error: $error');
      debugPrint('Error type: ${error.runtimeType}');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<void> sendEmailVerification([AuthUser? user]) async {
    debugPrint('========== SEND EMAIL VERIFICATION START ==========');
    debugPrint('Email verification requested.');
    try {
      final targetUser = user?._firebaseUser ?? _auth.currentUser;
      debugPrint('Target user: ${targetUser?.email ?? 'null'}');
      
      if (targetUser == null) {
        debugPrint('ERROR: No signed-in user available');
        throw const AuthUnavailableException('No signed-in user available.');
      }
      
      debugPrint('Calling sendEmailVerification()...');
      await targetUser.sendEmailVerification();
      debugPrint('Verification email sent successfully to ${targetUser.email}');
      debugPrint('========== SEND EMAIL VERIFICATION SUCCESS ==========');
    } on FirebaseAuthException catch (error) {
      debugPrint('========== SEND EMAIL VERIFICATION FAILED ==========');
      debugPrint('Exception code: ${error.code}');
      debugPrint('Exception message: ${error.message}');
      debugPrintStack(stackTrace: StackTrace.current);
      throw Exception(getErrorMessage(error));
    } catch (error, stackTrace) {
      debugPrint('========== SEND EMAIL VERIFICATION ERROR ==========');
      debugPrint('Unexpected error: $error');
      debugPrint('Error type: ${error.runtimeType}');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

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
      throw Exception(getErrorMessage(error));
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
    if (error is FirebaseAuthException) {
      switch (error.code) {
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
}
