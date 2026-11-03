import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_theme.dart';
import '../core/context_extensions.dart';
import '../services/api_service.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/decorative_blobs.dart';

final RegExp _emailFormatPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static final RegExp _specialCharacterPattern =
      RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-+=~`\[\];'/\\]''');

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool? _emailExists;
  bool _isCheckingEmail = false;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_onEmailFocusChanged);
  }

  @override
  void dispose() {
    _emailFocusNode.removeListener(_onEmailFocusChanged);
    _emailFocusNode.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onEmailFocusChanged() {
    if (!_emailFocusNode.hasFocus) {
      _checkEmailExists();
    }
  }

  Future<void> _checkEmailExists() async {
    final email = _emailController.text.trim();
    if (!_emailFormatPattern.hasMatch(email)) {
      return;
    }
    setState(() => _isCheckingEmail = true);
    final exists = await ApiService.checkEmailExists(email);
    if (!mounted || _emailController.text.trim() != email) return;
    setState(() {
      _emailExists = exists;
      _isCheckingEmail = false;
    });
  }

  Future<void> _handleRegister() async {
    if (_isLoading || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    debugPrint('Register attempt started for $email');

    try {
      final user = await FirebaseAuthService.registerWithEmailAndPassword(
        name: name,
        email: email,
        password: password,
      );

      debugPrint('Register successful for $email, user: ${user.email}, verified: ${user.emailVerified}');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.trRead('account_created_verify')),
          backgroundColor: AppTheme.primary,
        ),
      );
      context.go('/verify-email');
    } on Exception catch (e) {
      debugPrint('Register failed with exception: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(FirebaseAuthService.getErrorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Register failed with unexpected error: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const CustomAppBar(),
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
                    const SizedBox(height: 20),
                    Text(
                      context.tr('create_account'),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('create_simple_account'),
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 36),
                    CustomTextField(
                      hintText: context.tr('full_name_hint'),
                  controller: _nameController,
                  prefixIcon: const Icon(Icons.person_outlined),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.trRead('please_enter_name');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  hintText: context.tr('email_hint'),
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.trRead('please_enter_email');
                    }
                    if (!_emailFormatPattern.hasMatch(value)) {
                      return context.trRead('please_enter_valid_email');
                    }
                    if (_emailExists == true) {
                      return context.trRead('email_already_registered');
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() => _emailExists = null),
                ),
                if (_isCheckingEmail)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      context.tr('checking_email'),
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  )
                else if (_emailExists == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 16, color: Colors.red),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            context.tr('email_already_registered'),
                            style: TextStyle(fontSize: 12, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                CustomTextField(
                  hintText: context.tr('password_hint'),
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.trRead('please_enter_password');
                    }
                    if (value.length < 8) {
                      return context.trRead('password_min_length');
                    }
                    if (!RegExp(r'[A-Z]').hasMatch(value)) {
                      return context.trRead('password_needs_uppercase');
                    }
                    if (!RegExp(r'[a-z]').hasMatch(value)) {
                      return context.trRead('password_needs_lowercase');
                    }
                    if (!RegExp(r'[0-9]').hasMatch(value)) {
                      return context.trRead('password_needs_number');
                    }
                    if (!_specialCharacterPattern.hasMatch(value)) {
                      return context.trRead('password_needs_special');
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                _buildRequirementRow(
                  context.tr('req_8_characters'),
                  _passwordController.text.length >= 8,
                ),
                _buildRequirementRow(
                  context.tr('req_uppercase'),
                  RegExp(r'[A-Z]').hasMatch(_passwordController.text),
                ),
                _buildRequirementRow(
                  context.tr('req_lowercase'),
                  RegExp(r'[a-z]').hasMatch(_passwordController.text),
                ),
                _buildRequirementRow(
                  context.tr('req_number'),
                  RegExp(r'[0-9]').hasMatch(_passwordController.text),
                ),
                _buildRequirementRow(
                  context.tr('req_special_char'),
                  _specialCharacterPattern.hasMatch(_passwordController.text),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  hintText: context.tr('confirm_password_hint'),
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.trRead('please_confirm_password');
                    }
                    if (value != _passwordController.text) {
                      return context.trRead('passwords_do_not_match');
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                if (_confirmPasswordController.text.isNotEmpty)
                  _buildConfirmPasswordStatus(context),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: context.tr('create_account'),
                        onPressed: _isLoading ? null : _handleRegister,
                        isLoading: _isLoading,
                        borderRadius: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: context.tr('already_have_account_q')),
                              TextSpan(
                                text: context.tr('sign_in'),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(String label, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: met ? Colors.green : AppTheme.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: met ? Colors.green : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmPasswordStatus(BuildContext context) {
    final matches = _confirmPasswordController.text == _passwordController.text;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(
            matches ? Icons.check_circle : Icons.error_outline,
            size: 16,
            color: matches ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 6),
          Text(
            matches ? context.tr('passwords_match') : context.tr('passwords_do_not_match'),
            style: TextStyle(
              fontSize: 12,
              color: matches ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
