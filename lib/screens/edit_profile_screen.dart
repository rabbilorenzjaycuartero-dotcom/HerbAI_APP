import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/context_extensions.dart';
import '../services/firebase_auth_service.dart';
import '../utils/name_input.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/demographics_fields.dart';
import '../providers/user_profile_store.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();
  late final DemographicsController _demographics;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: FirebaseAuthService.currentUser?.displayName ?? '',
    );
    final profile = userProfileStore.profile;
    _demographics = DemographicsController(
      initialAge: profile?.age,
      initialDesignation: profile?.designation,
      initialOther: profile?.designationOther,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _demographics.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    final nameError = validateName(_nameController.text, context);
    if (nameError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(nameError), backgroundColor: Colors.orange),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      final name = normalizeName(_nameController.text);
      await FirebaseAuthService.updateProfile(displayName: name);
      await userProfileStore.save(
        name: name,
        email: FirebaseAuthService.currentUser?.email ?? '',
        age: _demographics.ageValue!,
        designation: _demographics.designation!,
        designationOther: _demographics.otherValue,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Failed to save profile: $e');
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.trRead('could_not_save_changes')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: CustomAppBar(title: context.tr('edit_profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 60,
                backgroundColor: AppTheme.primaryLight,
                child: const Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                hintText: context.tr('display_name_hint'),
                controller: _nameController,
                prefixIcon: const Icon(Icons.person_outlined),
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.words,
                inputFormatters: nameInputFormatters,
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: DemographicsFields(controller: _demographics, enabled: !_isSaving),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: context.tr('save_changes'),
                  onPressed: _isSaving ? null : _handleSave,
                  isLoading: _isSaving,
                  borderRadius: 30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
