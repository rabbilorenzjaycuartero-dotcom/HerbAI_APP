import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_constants.dart';
import '../core/app_theme.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/decorative_blobs.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Once the auth check finishes, an unauthenticated user sees the welcome
  // buttons in-place instead of being routed straight to /login.
  bool _showWelcome = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(_controller);

    _controller.forward();

    Timer(const Duration(seconds: 1), () async {
      if (!mounted) return;

      final user = FirebaseAuthService.currentUser;

      if (user != null) {
        AuthUser? refreshedUser;
        try {
          // refreshCurrentUser() hits Firebase over the network with no
          // timeout of its own -- without this, a slow/unresponsive network
          // call here leaves the splash screen spinning forever with no
          // way out. On timeout, fall back to the cached (pre-refresh)
          // user instead of blocking, so a flaky connection doesn't strand
          // an already-known-verified user on the splash screen.
          refreshedUser = await FirebaseAuthService.refreshCurrentUser()
              .timeout(const Duration(seconds: 8));
        } on TimeoutException {
          debugPrint('Auth refresh timed out; falling back to cached status.');
          refreshedUser = user;
        }
        if (!mounted) return;

        final isVerified = refreshedUser?.emailVerified ?? false;
        if (isVerified) {
          context.go('/');
        } else {
          context.go('/verify-email');
        }
      } else {
        setState(() => _showWelcome = true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          const DecorativeBlobs(),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _showWelcome ? _buildWelcome() : _buildSplash(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo({double size = 120, double iconSize = 72}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(size * 0.27),
      ),
      child: Icon(Icons.eco, size: iconSize, color: Colors.white),
    );
  }

  Widget _buildSplash() {
    return Center(
      key: const ValueKey('splash'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(scale: _scaleAnimation, child: _buildLogo()),
          ),
          const SizedBox(height: 24),
          FadeTransition(
            opacity: _fadeAnimation,
            child: const Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                AppConstants.tagline,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return Padding(
      key: const ValueKey('welcome'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLogo(size: 110, iconSize: 60),
          const SizedBox(height: 16),
          const Text(
            AppConstants.appName,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppConstants.tagline,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 48),
          Text(
            'WELCOME',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'LOG IN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'SIGN UP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
