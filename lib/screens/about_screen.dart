import 'package:flutter/material.dart';
import '../widgets/custom_appbar.dart';
import '../core/app_theme.dart';
import '../core/app_constants.dart';
import '../core/context_extensions.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: context.tr('about_herbai_title')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(32.0),
                ),
                child: const Icon(
                  Icons.eco,
                  size: 72,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppConstants.appName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              Text(
                context.tr('version_1_0_0'),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('developer_team'),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 32),
              _buildSection(
                context,
                context.tr('research_title_label'),
                context.tr('research_title_value'),
                isBold: true,
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                context.tr('app_description_label'),
                context.tr('app_description_value'),
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                context.tr('our_mission_label'),
                context.tr('our_mission_value'),
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                context.tr('our_vision_label'),
                context.tr('our_vision_value'),
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                context.tr('research_development_label'),
                context.tr('research_development_value'),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                context.tr('copyright_herbai'),
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isBold ? AppTheme.primary : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            color: AppTheme.textSecondary,
            height: 1.5,
            fontSize: isBold ? 15 : 16,
            fontStyle: isBold ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );
  }
}
