import 'package:flutter/material.dart';
import '../widgets/custom_appbar.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Privacy Policy'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Last Updated: July 2026',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              _buildSection(
                '1. Data Collection',
                'HERBIA is designed to prioritize your privacy. Currently, the application operates entirely locally on your device and does not collect any personal data, user information, or usage statistics. All data, including your favorite plants, settings, and search history, is stored locally on your device using SharedPreferences.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                '2. User Privacy',
                'We are committed to protecting your privacy. Since no data is collected from your device, there is no risk of your personal information being shared, sold, or accessed by third parties. Your herbal plant preferences and usage remain completely private and confidential.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                '3. Local Storage',
                'All application data is stored locally on your mobile device. This includes:\n• Theme preferences (light/dark mode)\n• Notification settings\n• Language selection\n• Favorite plants\n• Recent searches\n\nYou can clear this data at any time by resetting your settings within the application or by uninstalling the app.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                '4. Future AI Features',
                'Future versions of HERBIA may include AI-driven features such as plant identification and personalized recommendations. These features will be optional, and we will update this privacy policy accordingly before implementing any changes that involve data collection or processing outside of your device.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                '5. Contact Information',
                'If you have any questions or concerns about this privacy policy or the HERBIA application, please contact us at:\n\nEmail: privacy@herbia.app\nAddress: Herbal Research Institute, Cebu, Philippines',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
