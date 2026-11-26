import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/context_extensions.dart';

/// Curved green header with a "Step X of Y" progress bar, used by the
/// Select Your Symptoms (step 1) and Before We Recommend (step 2) screens.
/// Same look as the Home, Recommend and Login headers.
class StepHeader extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  /// Extra bottom space so content below can overlap the curve.
  final double bottomPadding;

  /// Hides the title and subtitle (e.g. while the keyboard is open) so the
  /// screen keeps room for its content.
  final bool compact;

  const StepHeader({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
    required this.onBack,
    this.bottomPadding = 56,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return ClipPath(
      clipper: _StepHeaderClipper(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(12, topInset + 4, 20, bottomPadding),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B5E20), AppTheme.primary, Color(0xFF43A047)],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -28,
              top: 0,
              child: Transform.rotate(
                angle: -0.5,
                child: Icon(
                  Icons.eco,
                  size: 120,
                  color: Colors.white.withValues(alpha: 0.09),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                    ),
                    Text(
                      '${context.tr('step_label')} $step ${context.tr('of_label')} $totalSteps',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      // Progress bar: one segment per step.
                      Row(
                        children: [
                          for (var i = 1; i <= totalSteps; i++) ...[
                            Expanded(
                              child: Container(
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(
                                    alpha: i <= step ? 0.95 : 0.3,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            if (i < totalSteps) const SizedBox(width: 6),
                          ],
                        ],
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 16),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final h = size.height;
    final w = size.width;
    return Path()
      ..lineTo(0, h - 36)
      ..quadraticBezierTo(w * 0.3, h, w * 0.6, h - 20)
      ..quadraticBezierTo(w * 0.85, h - 34, w, h - 10)
      ..lineTo(w, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Full-width primary button pinned to the bottom of a step screen.
class StepBottomBar extends StatelessWidget {
  final Widget child;

  const StepBottomBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
