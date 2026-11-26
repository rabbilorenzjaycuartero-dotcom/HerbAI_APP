import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'app_logo.dart';

/// Shared look for the Login and Create Account screens: a curved green
/// header with the HerbAI logo, title and subtitle, and the form on a
/// rounded card that overlaps the curve. The header and card fade/slide in
/// once when the screen opens.
class AuthScaffold extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget child;

  /// Shown below the card (e.g. "Don't have an account? Sign up").
  final Widget? footer;

  /// Shows a back arrow in the header when set.
  final VoidCallback? onBack;

  /// Extra layers on top of everything (e.g. the login error banner).
  final List<Widget> overlays;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
    this.onBack,
    this.overlays = const [],
  });

  @override
  State<AuthScaffold> createState() => _AuthScaffoldState();
}

class _AuthScaffoldState extends State<AuthScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  late final Animation<double> _headerFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.6, curve: Curves.easeOut),
  );
  late final Animation<double> _cardFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.25, 1, curve: Curves.easeOut),
  );
  late final Animation<Offset> _cardSlide =
      Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.25, 1, curve: Curves.easeOutCubic),
        ),
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  FadeTransition(
                    opacity: _headerFade,
                    child: _buildHeader(context, topInset),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -44),
                    child: FadeTransition(
                      opacity: _cardFade,
                      child: SlideTransition(
                        position: _cardSlide,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              _buildCard(),
                              if (widget.footer != null) ...[
                                const SizedBox(height: 12),
                                widget.footer!,
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...widget.overlays,
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double topInset) {
    return ClipPath(
      clipper: _CurvedBottomClipper(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(24, topInset + 24, 24, 100),
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
            // Soft leaf shapes in the corners for a herbal feel.
            Positioned(
              right: -30,
              top: -10,
              child: Transform.rotate(
                angle: -0.5,
                child: Icon(
                  Icons.eco,
                  size: 150,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -30,
              child: Transform.rotate(
                angle: 0.7,
                child: Icon(
                  Icons.spa,
                  size: 120,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: double.infinity),
                if (widget.onBack != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                    ),
                  )
                else
                  const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const AppLogo(size: 92),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: widget.child,
    );
  }
}

/// Gentle wave along the bottom edge of the header.
class _CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final h = size.height;
    final w = size.width;
    return Path()
      ..lineTo(0, h - 56)
      ..quadraticBezierTo(w * 0.25, h, w * 0.5, h - 28)
      ..quadraticBezierTo(w * 0.78, h - 58, w, h - 18)
      ..lineTo(w, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
