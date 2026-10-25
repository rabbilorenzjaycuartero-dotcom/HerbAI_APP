import 'package:flutter/material.dart';
import '../widgets/custom_appbar.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Terms and Conditions'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Terms and Conditions',
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
                '1. User Responsibilities',
                'By using the HERBAI application, you agree to use it responsibly and for educational purposes only. The information provided in this app is based on ethnobotanical knowledge and should not replace professional medical advice.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                '2. Acceptable Use',
                'You agree to:\n• Use the app for personal, non-commercial purposes only\n• Not misuse or attempt to reverse-engineer the application\n• Respect intellectual property rights of the developers and researchers\n• Not use the app for any illegal or unauthorized purpose',
              ),
              const SizedBox(height: 24),
              _buildSection(
                '3. Medical Disclaimer',
                'THE INFORMATION PROVIDED BY HERBAI IS FOR GENERAL EDUCATIONAL PURPOSES ONLY. IT IS NOT INTENDED TO BE A SUBSTITUTE FOR PROFESSIONAL MEDICAL ADVICE, DIAGNOSIS, OR TREATMENT. ALWAYS SEEK THE ADVICE OF YOUR PHYSICIAN OR OTHER QUALIFIED HEALTH PROVIDER WITH ANY QUESTIONS YOU MAY HAVE REGARDING A MEDICAL CONDITION.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                '4. Limitation of Liability',
                'IN NO EVENT SHALL THE DEVELOPERS, RESEARCHERS, OR AFFILIATES BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES ARISING OUT OF OR IN ANY WAY CONNECTED WITH THE USE OF THIS APPLICATION.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                '5. Future Updates',
                'We reserve the right to modify or update these terms and conditions at any time. Continued use of the application after changes are posted constitutes your acceptance of the revised terms.',
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
