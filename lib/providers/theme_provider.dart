import 'package:flutter/foundation.dart';
import '../services/settings_service.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = SettingsService.defaultDarkMode;
  bool _notificationsEnabled = SettingsService.defaultNotifications;
  String _selectedLanguage = SettingsService.defaultLanguage;

  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  String get selectedLanguage => _selectedLanguage;

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _isDarkMode = await SettingsService.getDarkMode();
    _notificationsEnabled = await SettingsService.getNotificationsEnabled();
    _selectedLanguage = await SettingsService.getLanguage();
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    await SettingsService.setDarkMode(value);
    notifyListeners();
  }

  Future<void> toggleNotifications(bool value) async {
    _notificationsEnabled = value;
    await SettingsService.setNotificationsEnabled(value);
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    _selectedLanguage = language;
    await SettingsService.setLanguage(language);
    notifyListeners();
  }

  Future<void> resetSettings() async {
    await SettingsService.resetSettings();
    _isDarkMode = SettingsService.defaultDarkMode;
    _notificationsEnabled = SettingsService.defaultNotifications;
    _selectedLanguage = SettingsService.defaultLanguage;
    notifyListeners();
  }
}
