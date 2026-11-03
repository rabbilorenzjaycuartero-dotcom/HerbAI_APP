import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/context_extensions.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_appbar.dart';
import '../core/app_theme.dart';
import '../widgets/custom_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: context.tr('settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionTitle(context.tr('preferences')),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) => _buildSwitchTile(
                icon: Icons.dark_mode,
                title: themeProvider.t('dark_mode'),
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleDarkMode(value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value
                          ? themeProvider.t('dark_mode_enabled')
                          : themeProvider.t('dark_mode_disabled')),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) => _buildSwitchTile(
                icon: Icons.notifications,
                title: themeProvider.t('notifications'),
                value: themeProvider.notificationsEnabled,
                onChanged: (value) {
                  themeProvider.toggleNotifications(value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value
                          ? themeProvider.t('notifications_enabled')
                          : themeProvider.t('notifications_disabled')),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
            _buildLanguageTile(context),
            const Divider(height: 32),
            _buildSectionTitle(context.tr('about_section')),
            _buildMenuTile(
              icon: Icons.privacy_tip,
              title: context.tr('privacy_policy'),
              onTap: () {
                context.push('/privacy');
              },
            ),
            _buildMenuTile(
              icon: Icons.description,
              title: context.tr('terms_conditions'),
              onTap: () {
                context.push('/terms');
              },
            ),
            _buildMenuTile(
              icon: Icons.info,
              title: context.tr('about_herbai'),
              onTap: () {
                context.push('/about');
              },
            ),
            const SizedBox(height: 24),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) => CustomButton(
                text: themeProvider.t('reset_settings'),
                onPressed: () => _showResetDialog(context, themeProvider),
                isOutlined: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(title),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: const Icon(Icons.language, color: AppTheme.primary),
        title: Text(context.tr('language')),
        subtitle: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) => Text(
            themeProvider.selectedLanguage,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          _showLanguageDialog(context);
        },
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    // Language names are always shown in their own language/script (a
    // "Filipino" entry doesn't get translated when viewing in English, the
    // same way "Español" isn't translated in other apps' language pickers)
    // -- Cebuano is left out of the picker for now since it has no
    // translations behind it yet, same reason the Language setting needed
    // fixing in the first place.
    const languages = ['English', 'Filipino'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('select_language')),
        content: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) => SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final language = languages[index];
                return RadioListTile<String>(
                  value: language,
                  groupValue: themeProvider.selectedLanguage,
                  title: Text(language),
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setLanguage(value);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${themeProvider.t('language_set_to')} $value'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(themeProvider.t('reset_settings')),
        content: Text(themeProvider.t('reset_settings_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              themeProvider.t('cancel'),
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              await themeProvider.resetSettings();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(themeProvider.t('settings_reset_success')),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text(
              themeProvider.t('reset'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
