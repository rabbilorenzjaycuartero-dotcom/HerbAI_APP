import 'package:flutter/material.dart';
import '../widgets/custom_appbar.dart';
import '../core/context_extensions.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: context.tr('privacy_policy')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('privacy_policy'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('last_updated_july_2026'),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              _buildSection(
                context.tr('pp_section_1_title'),
                context.tr('pp_section_1_body'),
              ),
              const SizedBox(height: 24),
              _buildSection(
                context.tr('pp_section_2_title'),
                context.tr('pp_section_2_body'),
              ),
              const SizedBox(height: 24),
              _buildSection(
                context.tr('pp_section_3_title'),
                context.tr('pp_section_3_body'),
              ),
              const SizedBox(height: 24),
              _buildSection(
                context.tr('pp_section_4_title'),
                context.tr('pp_section_4_body'),
              ),
              const SizedBox(height: 24),
              _buildSection(
                context.tr('pp_section_5_title'),
                context.tr('pp_section_5_body'),
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
