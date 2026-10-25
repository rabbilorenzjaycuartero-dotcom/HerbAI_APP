import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'custom_button.dart';

/// Must-accept notice shown on every login clarifying HERBAI is an
/// educational Capstone project, not a substitute for professional medical
/// advice or a market-ready product.
class EducationalDisclaimerDialog extends StatelessWidget {
  const EducationalDisclaimerDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const EducationalDisclaimerDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          // The icon+title+body+button together can exceed the available
          // height on shorter/smaller-font screens; a Dialog otherwise
          // shrink-wraps its child at natural size and overflows instead of
          // scrolling. Scrolling the whole column (not just the body text)
          // guarantees everything -- including the accept button -- stays
          // reachable regardless of screen size or text scale.
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.school_outlined, size: 34, color: AppTheme.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  'Educational Use Notice',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'HERBAI is developed strictly for educational and research '
                  'purposes as a Capstone Project by students of Caraga State '
                  'University – Cabadbaran Campus (CSUCC).\n\n'
                  'The herbal recommendations and information provided are '
                  'based on gathered ethnobotanical knowledge and an AI model '
                  'still under development. They are not a substitute for '
                  'professional medical advice, diagnosis, or treatment. '
                  'Always consult a licensed healthcare professional before '
                  'using any herbal remedy.\n\n'
                  'This project is intended for further development and '
                  'deployment under the Forestry Program of Caraga State '
                  'University – Main Campus.\n\n'
                  'By tapping "I Understand & Accept," you acknowledge that '
                  'you are using this app for educational purposes only.',
                  style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'I Understand & Accept',
                    onPressed: () => Navigator.of(context).pop(),
                    borderRadius: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
