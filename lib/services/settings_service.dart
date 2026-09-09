import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyNotifications = 'notifications_enabled';
  static const String _keyLanguage = 'selected_language';

  // Default values
  static const bool defaultDarkMode = false;
  static const bool defaultNotifications = true;
  static const String defaultLanguage = 'English';

  // Dark Mode
  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? defaultDarkMode;
  }

  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  // Notifications
  static Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotifications) ?? defaultNotifications;
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
  }

  // Language
  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage) ?? defaultLanguage;
  }

  static Future<void> setLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, value);
  }

  // Reset all settings
  static Future<void> resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDarkMode);
    await prefs.remove(_keyNotifications);
    await prefs.remove(_keyLanguage);
  }
}
