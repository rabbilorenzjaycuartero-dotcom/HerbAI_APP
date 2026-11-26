import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/app_constants.dart';
import '../core/app_theme.dart';
import '../core/context_extensions.dart';
import '../providers/symptom_provider.dart';
import '../services/api_service.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/step_header.dart';

/// Step 2 of the Select Your Symptoms flow: special conditions that some
/// herbs carry precautions for (see condition_safety.py on the server).
class HealthCheckScreen extends StatelessWidget {
  const HealthCheckScreen({super.key});

  static const Map<String, IconData> _icons = {
    'pregnant': Icons.pregnant_woman_rounded,
    'breastfeeding': Icons.baby_changing_station_rounded,
    'child': Icons.child_care_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          StepHeader(
            step: 2,
            totalSteps: 2,
            title: context.tr('does_any_apply'),
            subtitle: context.tr('health_conditions_blurb'),
            onBack: () => Navigator.of(context).maybePop(),
            bottomPadding: 48,
          ),
          Expanded(
            child: Consumer<SymptomProvider>(
              builder: (context, provider, child) {
                final none = provider.selectedConditions.isEmpty;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  children: [
                    for (final condition in AppConstants.healthConditions)
                      _ConditionCard(
                        icon:
                            _icons[condition.id] ??
                            Icons.health_and_safety_outlined,
                        label: context.tr(condition.id),
                        description: context.tr(
                          'condition_desc_${condition.id}',
                        ),
                        isSelected: provider.selectedConditions.contains(
                          condition.id,
                        ),
                        onTap: () => provider.toggleCondition(condition.id),
                      ),
                    _ConditionCard(
                      icon: Icons.do_not_disturb_on_outlined,
                      label: context.tr('none_of_these'),
                      description: context.tr('none_of_these_desc'),
                      isSelected: none,
                      onTap: provider.clearConditions,
                    ),
                  ],
                );
              },
            ),
          ),
          StepBottomBar(
            child: CustomButton(
              text: context.tr('show_recommendations'),
              onPressed: () {
                _logChecklistSearch(context.read<SymptomProvider>());
                context.push('/recommendations');
              },
              borderRadius: 30,
              icon: Icons.arrow_forward_rounded,
              elevation: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConditionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConditionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.08)
                  : AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primary
                    : AppTheme.textSecondary.withValues(alpha: 0.15),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : AppTheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.textSecondary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Logs this checklist search for the admin usage reports (most common
/// concerns). Runs in the background; navigation never waits for it.
Future<void> _logChecklistSearch(SymptomProvider provider) async {
  final symptoms = provider.selectedSymptoms.map((s) => s.id).toList();
  if (symptoms.isEmpty) return;
  final conditions = provider.selectedConditions.toList();
  final token = await FirebaseAuthService.getIdToken();
  if (token == null) return;
  await ApiService.logChecklistSearch(
    idToken: token,
    symptoms: symptoms,
    conditions: conditions,
  );
}
