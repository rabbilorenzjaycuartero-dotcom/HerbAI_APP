import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_theme.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_button.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isLoading = false;
  bool _isResending = false;

  Future<void> _checkEmailVerified() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('Checking email verification status...');
      final user = await FirebaseAuthService.refreshCurrentUser();
      if (!mounted) return;

      final isVerified = user?.emailVerified ?? false;
      debugPrint('Email verified: $isVerified for ${user?.email}');

      if (isVerified) {
        debugPrint('Email verified, navigating to home');
        context.go('/');
        return;
      }

      debugPrint('Email not verified yet');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your email has not been verified yet. Please check your inbox.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      debugPrint('Error checking email verification: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendEmailVerification() async {
    setState(() => _isResending = true);

    try {
      debugPrint('Resending verification email...');
      await FirebaseAuthService.sendEmailVerification();
      if (!mounted) return;
      debugPrint('Verification email resent successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent again. Please check your inbox.'),
          backgroundColor: AppTheme.primary,
        ),
      );
    } catch (e) {
      debugPrint('Failed to resend verification email: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'Verify your email',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a verification link to ${FirebaseAuthService.currentUser?.email ?? "your email"}.',
                style: TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Icon(
                Icons.mark_email_unread_outlined,
                size: 96,
                color: AppTheme.primary,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: _isResending ? 'Sending...' : 'Resend email',
                onPressed: _isResending ? null : _resendEmailVerification,
                isOutlined: true,
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: _isLoading ? 'Checking...' : 'I verified it',
                onPressed: _isLoading ? null : _checkEmailVerified,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await FirebaseAuthService.signOut();
                  if (mounted) {
                    context.go('/login');
                  }
                },
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
