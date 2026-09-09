import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_constants.dart';
import '../core/app_theme.dart';
import '../services/firebase_auth_service.dart';

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

      debugPrint('Splash screen: checking auth state');
      final user = FirebaseAuthService.currentUser;
      debugPrint('Splash screen: current user = ${user?.email ?? 'null'}');

      if (user != null) {
        debugPrint('Splash screen: refreshing user data');
        final refreshedUser = await FirebaseAuthService.refreshCurrentUser();
        if (!mounted) return;
        
        final isVerified = refreshedUser?.emailVerified ?? false;
        debugPrint('Splash screen: email verified = $isVerified');
        
        if (isVerified) {
          debugPrint('Splash screen: navigating to home');
          context.go('/');
        } else {
          debugPrint('Splash screen: navigating to verify-email');
          context.go('/verify-email');
        }
      } else {
        debugPrint('Splash screen: no user, navigating to login');
        context.go('/login');
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Icon(Icons.eco, size: 72, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                AppConstants.appName,
                style: const TextStyle(
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
      ),
    );
  }
}
