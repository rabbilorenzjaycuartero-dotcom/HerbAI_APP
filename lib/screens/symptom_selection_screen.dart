import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/symptom_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_widget.dart';
import '../widgets/step_header.dart';
import '../core/app_theme.dart';
import '../core/context_extensions.dart';
import '../models/plant_model.dart';

class SymptomSelectionScreen extends StatefulWidget {
  const SymptomSelectionScreen({super.key});

  @override
  State<SymptomSelectionScreen> createState() => _SymptomSelectionScreenState();
}

class _SymptomSelectionScreenState extends State<SymptomSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          StepHeader(
            step: 1,
            totalSteps: 2,
            title: context.tr('what_symptoms_experiencing'),
            subtitle: context.tr('choose_all_symptoms'),
            onBack: () => context.go('/'),
            bottomPadding: 60,
            compact: MediaQuery.viewInsetsOf(context).bottom > 0,
          ),
          Transform.translate(
            offset: const Offset(0, -30),
            child: _buildSearchBar(context),
          ),
          Transform.translate(
            offset: const Offset(0, -22),
            child: _buildSelectedSymptoms(),
          ),
          Expanded(child: _buildSymptomsList()),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: AppTheme.background,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(18),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
          decoration: InputDecoration(
            hintText: context.tr('search_symptoms_hint'),
            hintStyle: TextStyle(
              color: AppTheme.textSecondary.withValues(alpha: 0.7),
            ),
            prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primary),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: AppTheme.background,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedSymptoms() {
    return Consumer<SymptomProvider>(
      builder: (context, provider, child) {
        if (provider.selectedSymptoms.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      context.tr('selected_symptoms'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${provider.selectedSymptoms.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: provider.clearSymptoms,
                      child: Text(context.tr('clear_all')),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.selectedSymptoms.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final symptom = provider.selectedSymptoms[index];
                    return _SelectedSymptomChip(
                      key: ValueKey(symptom.id),
                      symptom: symptom,
                      onRemove: () => provider.toggleSymptom(symptom),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSymptomsList() {
    return Consumer<SymptomProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingSymptoms) {
          return const LoadingWidget();
        }

        final filteredSymptoms = _getFilteredSymptoms(provider);

        if (filteredSymptoms.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                '${context.tr(_searchQuery.isNotEmpty ? 'search_results' : 'all_symptoms')} (${filteredSymptoms.length})',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: filteredSymptoms
                  .map(
                    (symptom) => _SymptomChip(
                      symptom: symptom,
                      isSelected: provider.isSymptomSelected(symptom),
                      onTap: () => provider.toggleSymptom(symptom),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppTheme.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('no_symptoms_found'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('try_adjusting_search'),
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Symptom> _getFilteredSymptoms(SymptomProvider provider) {
    if (_searchQuery.isEmpty) {
      return provider.allSymptoms;
    }

    return provider.allSymptoms
        .where((symptom) => symptom.name.toLowerCase().contains(_searchQuery))
        .toList();
  }

  Widget _buildBottomButton() {
    return Consumer<SymptomProvider>(
      builder: (context, provider, child) {
        final count = provider.selectedSymptoms.length;
        return StepBottomBar(
          child: CustomButton(
            text: count > 0
                ? '${context.tr('continue_label')} ($count)'
                : context.tr('continue_label'),
            icon: Icons.arrow_forward_rounded,
            onPressed: provider.hasSelectedSymptoms
                ? () => context.push('/health-check')
                : null,
            borderRadius: 30,
          ),
        );
      },
    );
  }
}

class _SelectedSymptomChip extends StatelessWidget {
  final Symptom symptom;
  final VoidCallback onRemove;

  const _SelectedSymptomChip({
    required Key key,
    required this.symptom,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      constraints: const BoxConstraints(maxWidth: 220),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              symptom.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 17,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SymptomChip extends StatelessWidget {
  final Symptom symptom;
  final bool isSelected;
  final VoidCallback onTap;

  const _SymptomChip({
    required this.symptom,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: const BoxConstraints(maxWidth: 260),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.1)
                  : AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primary
                    : AppTheme.textSecondary.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    key: ValueKey(isSelected),
                    size: 20,
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    symptom.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.textPrimary,
                    ),
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
