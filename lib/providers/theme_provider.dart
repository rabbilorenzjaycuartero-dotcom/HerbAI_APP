import 'package:flutter/foundation.dart';
import '../core/app_theme.dart';
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
    AppTheme.isDark = _isDarkMode;
    _notificationsEnabled = await SettingsService.getNotificationsEnabled();
    _selectedLanguage = await SettingsService.getLanguage();
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    AppTheme.isDark = value;
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
    AppTheme.isDark = _isDarkMode;
    _notificationsEnabled = SettingsService.defaultNotifications;
    _selectedLanguage = SettingsService.defaultLanguage;
    notifyListeners();
  }
}
