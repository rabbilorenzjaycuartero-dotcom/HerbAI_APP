import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_appbar.dart';
import '../core/app_theme.dart';
import '../widgets/custom_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Settings'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionTitle('Preferences'),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) => _buildSwitchTile(
                icon: Icons.dark_mode,
                title: 'Dark Mode',
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleDarkMode(value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value ? 'Dark mode enabled' : 'Dark mode disabled'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) => _buildSwitchTile(
                icon: Icons.notifications,
                title: 'Notifications',
                value: themeProvider.notificationsEnabled,
                onChanged: (value) {
                  themeProvider.toggleNotifications(value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value ? 'Notifications enabled' : 'Notifications disabled'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
            _buildLanguageTile(context),
            const Divider(height: 32),
            _buildSectionTitle('About'),
            _buildMenuTile(
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              onTap: () {
                context.push('/privacy');
              },
            ),
            _buildMenuTile(
              icon: Icons.description,
              title: 'Terms & Conditions',
              onTap: () {
                context.push('/terms');
              },
            ),
            _buildMenuTile(
              icon: Icons.info,
              title: 'About HERBIA',
              onTap: () {
                context.push('/about');
              },
            ),
            const SizedBox(height: 24),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) => CustomButton(
                text: 'Reset Settings',
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
        title: const Text('Language'),
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
    const languages = ['English', 'Filipino', 'Cebuano'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
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
                          content: Text('Language set to $value'),
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
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to default?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              await themeProvider.resetSettings();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings reset successfully'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
