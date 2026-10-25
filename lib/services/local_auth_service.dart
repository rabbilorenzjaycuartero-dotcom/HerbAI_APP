import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthService {
  static const String _keyRememberMe = 'remember_me';
  static const String _keySavedEmail = 'saved_email';

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
}
