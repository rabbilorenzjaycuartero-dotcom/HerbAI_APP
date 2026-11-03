import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_theme.dart';
import '../core/context_extensions.dart';
import '../services/api_service.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_button.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _codeController = TextEditingController();
  bool _isVerifying = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Best-effort, silent: a code may already be sitting in the user's
    // inbox from registration (still within its 10-minute window) or from
    // a previous visit to this screen, so a quiet cooldown rejection here
    // isn't an error worth surfacing -- only an explicit "Resend" tap shows
    // feedback either way.
    _sendCode(silent: true);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode({bool silent = false}) async {
    if (!silent) setState(() => _isSending = true);
    final token = await FirebaseAuthService.getIdToken();
    final sent = token != null && await ApiService.sendVerificationCode(token);
    if (!mounted || silent) return;
    setState(() => _isSending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sent
              ? context.trRead('verification_code_sent')
              : context.trRead('could_not_send_code'),
        ),
        backgroundColor: sent ? AppTheme.primary : Colors.red,
      ),
    );
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.trRead('enter_6_digit_code')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);
    final token = await FirebaseAuthService.getIdToken();
    if (!mounted) return;
    final error = token == null
        ? context.trRead('not_signed_in')
        : await ApiService.verifyEmailCode(token, code);
    if (!mounted) return;

    if (error == null) {
      await FirebaseAuthService.refreshCurrentUser();
      if (!mounted) return;
      context.go('/');
      return;
    }

    setState(() => _isVerifying = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error), backgroundColor: Colors.red),
    );
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
                context.tr('verify_your_email'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '${context.tr('we_sent_6_digit_code_to')} ${FirebaseAuthService.currentUser?.email ?? context.tr('your_email_fallback')}.',
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
              TextField(
                controller: _codeController,
                enabled: !_isVerifying,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '------',
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: _isVerifying ? context.tr('verifying') : context.tr('verify'),
                onPressed: _isVerifying ? null : _verifyCode,
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: _isSending ? context.tr('sending') : context.tr('resend_code'),
                onPressed: _isSending ? null : () => _sendCode(),
                isOutlined: true,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await FirebaseAuthService.signOut();
                  if (mounted) {
                    context.go('/login');
                  }
                },
                child: Text(context.tr('sign_out')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
