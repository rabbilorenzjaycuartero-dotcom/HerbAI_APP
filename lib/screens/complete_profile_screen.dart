import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_theme.dart';
import '../core/context_extensions.dart';
import '../providers/user_profile_store.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/app_logo.dart';
import '../widgets/custom_button.dart';
import '../widgets/decorative_blobs.dart';
import '../widgets/demographics_fields.dart';

/// Shown once to accounts created before Age/Designation were collected at
/// sign up. The router keeps the user here until the profile is complete.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _demographics = DemographicsController();
  bool _isSaving = false;

  @override
  void dispose() {
    _demographics.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    final user = FirebaseAuthService.currentUser;
    try {
      await userProfileStore.save(
        name: user?.displayName ?? '',
        email: user?.email ?? '',
        age: _demographics.ageValue!,
        designation: _demographics.designation!,
        designationOther: _demographics.otherValue,
      );
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      debugPrint('Complete profile failed: $e');
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trRead('could_not_save_changes')), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
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
                    const SizedBox(height: 16),
                    const Center(child: AppLogo(size: 88)),
                    const SizedBox(height: 20),
                    Text(
                      context.tr('complete_profile_title'),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('complete_profile_subtitle'),
                      style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 28),
                    DemographicsFields(controller: _demographics, enabled: !_isSaving),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('data_collection_notice'),
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: context.tr('continue_label'),
                        onPressed: _isSaving ? null : _save,
                        isLoading: _isSaving,
                        borderRadius: 30,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: _isSaving ? null : () => FirebaseAuthService.signOut(),
                        child: Text(context.tr('logout')),
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
}
