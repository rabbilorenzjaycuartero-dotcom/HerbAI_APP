import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyEmail = 'user_email';
  static const String _keyRememberMe = 'remember_me';
  static const String _keySavedEmail = 'saved_email';
  static const String _keyUserName = 'user_name';

  // Demo credentials
  static const String demoEmail = 'demo@herbia.com';
  static const String demoPassword = '12345678';

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Check if remember me is enabled
  static Future<bool> isRememberMeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberMe) ?? false;
  }

  // Get saved email for remember me
  static Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySavedEmail);
  }

  // Save remember me preference and email
  static Future<void> saveRememberMe(bool enabled, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, enabled);
    if (enabled) {
      await prefs.setString(_keySavedEmail, email);
    } else {
      await prefs.remove(_keySavedEmail);
    }
  }

  // Login with credentials
  static Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    if (email == demoEmail && password == demoPassword) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyEmail, email);
      if (rememberMe) {
        await saveRememberMe(true, email);
      }
      return true;
    }
    return false;
  }

  // Register user (mock)
  static Future<bool> register(String name, String email, String password) async {
    // For demo, just save the user locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyUserName, name);
    return true;
  }

  // Login as guest
  static Future<void> loginAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyEmail, 'guest@herbia.com');
    await prefs.setString(_keyUserName, 'Guest');
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyUserName);
    // Don't remove remember me or saved email here, keep them for next login
  }

  // Get current user email
  static Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  // Get current user name
  static Future<String?> getCurrentUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  // Send password reset email (mock)
  static Future<bool> sendPasswordResetEmail(String email) async {
    // For demo, just return true
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }
}