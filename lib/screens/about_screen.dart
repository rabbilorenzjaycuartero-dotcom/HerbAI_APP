import 'package:flutter/material.dart';
import '../widgets/custom_appbar.dart';
import '../core/app_theme.dart';
import '../core/app_constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'About HERBAI'),
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
              const Text(
                'Version 1.0.0',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Developer: Herbal Research Team',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 32),
              _buildSection(
                'Research Title',
                'AI-Driven Integration of Ethnobotanical Knowledge: A Mobile System for Local Herbal Plant Recommendations',
                isBold: true,
              ),
              const SizedBox(height: 24),
              _buildSection(
                'App Description',
                'HERBAI is a modern healthcare application that preserves and promotes ethnobotanical herbal knowledge. The application allows users to explore herbal plants, search medicinal information, save favorite plants, and prepares for future AI-powered herbal recommendations and plant image identification.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Our Mission',
                'To bridge the gap between traditional herbal knowledge and modern technology, making natural remedies accessible, reliable, and easy to discover for everyone worldwide.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Our Vision',
                'A world where traditional herbal wisdom is preserved, respected, and integrated with modern healthcare practices for the benefit of all.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Research & Development',
                'Our team works closely with botanists, traditional healers, and researchers to ensure accurate and reliable information. Future updates will include AI-powered recommendations and plant identification.',
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                '© 2026 HERBAI. All rights reserved.',
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

  Widget _buildSection(String title, String content, {bool isBold = false}) {
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
