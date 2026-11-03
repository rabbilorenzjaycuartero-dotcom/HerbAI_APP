import 'package:flutter/foundation.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = SettingsService.defaultDarkMode;
  bool _notificationsEnabled = SettingsService.defaultNotifications;
  String _selectedLanguage = SettingsService.defaultLanguage;

  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  String get selectedLanguage => _selectedLanguage;

  String t(String key) => AppStrings.t(key, _selectedLanguage);

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _isDarkMode = await SettingsService.getDarkMode();
    AppTheme.isDark = _isDarkMode;
    _notificationsEnabled = await SettingsService.getNotificationsEnabled();
    _selectedLanguage = await SettingsService.getLanguage();
    notifyListeners();

    if (_notificationsEnabled) {
      await _activateNotifications();
    }
  }

  // Re-subscribes to the new-herb broadcast topic and re-schedules the
  // health-check reminder from whatever last-check timestamp is already on
  // hand -- run both at startup (when the preference loads as enabled) and
  // whenever the toggle flips back on.
  Future<void> _activateNotifications() async {
    await NotificationService.subscribeToNewHerbTopic();
    final lastCheck = await SettingsService.getLastHealthCheckAt();
    if (lastCheck != null) {
      await NotificationService.scheduleHealthCheckReminder(lastCheck);
    }
  }

  Future<void> _deactivateNotifications() async {
    await NotificationService.unsubscribeFromNewHerbTopic();
    await NotificationService.cancelAllLocalReminders();
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

    if (value) {
      await _activateNotifications();
    } else {
      await _deactivateNotifications();
    }
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
    final wasEnabled = _notificationsEnabled;
    _notificationsEnabled = SettingsService.defaultNotifications;
    _selectedLanguage = SettingsService.defaultLanguage;
    notifyListeners();

    if (_notificationsEnabled && !wasEnabled) {
      await _activateNotifications();
    } else if (!_notificationsEnabled && wasEnabled) {
      await _deactivateNotifications();
    }
  }
}
