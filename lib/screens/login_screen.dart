import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_theme.dart';
import '../services/api_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/local_auth_service.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/decorative_blobs.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  int _failedAttemptCount = 0;

  // Top-banner notification state. _isLocked additionally disables the
  // email/password fields and the live countdown overrides _bannerMessage
  // every tick, so the user is never left guessing how much longer it is.
  String? _bannerMessage;
  bool _bannerIsLockout = false;
  bool _isLocked = false;
  int _remainingLockoutSeconds = 0;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    final email = await LocalAuthService.getSavedEmail();
    final rememberMe = await LocalAuthService.isRememberMeEnabled();
    if (!mounted) return;
    setState(() {
      _emailController.text = email ?? '';
      _rememberMe = rememberMe && email != null;
    });
    // If this remembered account is still serving out a lock from a
    // previous visit, surface that immediately instead of waiting for the
    // user to press Sign In and find out.
    if (email != null && email.isNotEmpty) {
      final lockout = await ApiService.checkLoginLockout(email.toLowerCase());
      if (mounted && lockout['locked'] == true) {
        _startLockoutCountdown(lockout['remainingSeconds'] as int);
      }
    }
  }

  void _startLockoutCountdown(int seconds) {
    _lockoutTimer?.cancel();
    setState(() {
      _isLocked = true;
      _bannerIsLockout = true;
      _remainingLockoutSeconds = seconds;
      _bannerMessage = 'Too many attempts. Try again in ${seconds}s.';
    });
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingLockoutSeconds--;
        if (_remainingLockoutSeconds <= 0) {
          _isLocked = false;
          _bannerMessage = null;
          timer.cancel();
        } else {
          _bannerMessage = 'Too many attempts. Try again in ${_remainingLockoutSeconds}s.';
        }
      });
    });
  }

  /// Firebase deliberately returns the exact same error for a wrong
  /// password and for an email that isn't registered at all (anti
  /// -enumeration protection -- confirmed by testing directly against this
  /// project), so telling them apart means asking our own backend, which
  /// has privileged (Admin SDK) visibility into real accounts via
  /// /check-email. This is a deliberate trade of a slice of that
  /// protection for a clearer message, same choice already made for the
  /// Register screen's "email already registered" hint.
  Future<String> _describeLoginFailure(Object error, String lockoutEmail) async {
    // Normalized because the exact code string varies by platform -- e.g.
    // Android's native SDK returns "ERROR_INVALID_CREDENTIAL" (confirmed by
    // testing on-device) where iOS/other platforms return the lowercase
    // "invalid-credential" the rest of this app's code assumes elsewhere.
    final code = FirebaseAuthService.errorCode(error)?.toLowerCase().replaceAll('_', '-') ?? '';
    final isCredentialMismatch = code.contains('invalid-credential') ||
        code.contains('wrong-password') ||
        code.contains('user-not-found');
    if (!isCredentialMismatch) {
      return FirebaseAuthService.getErrorMessage(error);
    }
    final exists = await ApiService.checkEmailExists(lockoutEmail);
    if (exists == false) {
      return 'Incorrect email.';
    }
    return 'Incorrect password.';
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading || _isLocked || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _bannerMessage = null;
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final lockoutEmail = email.toLowerCase();

    final lockout = await ApiService.checkLoginLockout(lockoutEmail);
    if (lockout['locked'] == true) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _startLockoutCountdown(lockout['remainingSeconds'] as int);
      return;
    }

    debugPrint('Login attempt started for $email');

    try {
      await FirebaseAuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await ApiService.recordLoginSuccess(lockoutEmail);

      debugPrint('Login successful, saving remember me preference');
      await LocalAuthService.saveRememberMe(
        _rememberMe,
        email,
      );

      final refreshedUser = await FirebaseAuthService.refreshCurrentUser();
      debugPrint('User refreshed: ${refreshedUser?.email}, verified: ${refreshedUser?.emailVerified}');

      if (!mounted) return;

      // Route guard will handle navigation based on email verification status
      context.go('/');
    } on Exception catch (e) {
      debugPrint('Login failed with exception: $e');
      final failureResult = await ApiService.recordLoginFailure(lockoutEmail);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _failedAttemptCount++;
      });
      if (failureResult['locked'] == true) {
        _startLockoutCountdown(failureResult['remainingSeconds'] as int);
      } else {
        final message = await _describeLoginFailure(e, lockoutEmail);
        if (!mounted) return;
        setState(() {
          _bannerIsLockout = false;
          _bannerMessage = message;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Login failed with unexpected error: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _bannerIsLockout = false;
        _bannerMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: const CustomAppBar(showBackButton: false),
        body: Stack(
          children: [
            const DecorativeBlobs(),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.eco, size: 44, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Welcome Back',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 36),
                  CustomTextField(
                    hintText: 'Email',
                    controller: _emailController,
                    enabled: !_isLocked,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    hintText: 'Password',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enabled: !_isLocked,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: _isLocked
                          ? null
                          : () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _rememberMe,
                    onChanged: _isLoading
                        ? null
                        : (value) => setState(() => _rememberMe = value ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Remember my email on this device'),
                  ),
                  if (_failedAttemptCount >= 2)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(color: AppTheme.primary),
                        ),
                      ),
                    ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: 'Sign In',
                          onPressed: (_isLoading || _isLocked) ? null : _handleLogin,
                          isLoading: _isLoading,
                          borderRadius: 30,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              "Don't have an account?",
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: () => context.go('/register'),
                            child: Text(
                              'Sign up',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildTopBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner() {
    if (_bannerMessage == null) return const SizedBox.shrink();
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Material(
          color: _bannerIsLockout ? Colors.orange.shade800 : Colors.red,
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  _bannerIsLockout ? Icons.lock_clock : Icons.warning_amber_rounded,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _bannerMessage!,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
