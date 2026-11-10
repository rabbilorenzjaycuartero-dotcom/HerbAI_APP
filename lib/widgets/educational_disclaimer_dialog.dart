import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/context_extensions.dart';
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
      barrierColor: Colors.black,
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
                  context.tr('educational_use_notice'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('educational_disclaimer_body'),
                  style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: context.tr('i_understand_accept'),
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
