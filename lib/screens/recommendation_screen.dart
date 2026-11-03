import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/symptom_provider.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_button.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/recommendation_card.dart';
import '../models/plant_model.dart';
import '../core/app_theme.dart';
import '../core/app_constants.dart';
import '../core/context_extensions.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SymptomProvider>(context, listen: false).fetchRecommendations();
    });
    _recordHealthCheckCompleted();
  }

  // Reaching this screen means the user just finished a health check ->
  // symptom selection -> describe symptoms flow, so this is the natural
  // single signal to persist for the reminder -- no need to instrument
  // every screen in that flow individually.
  Future<void> _recordHealthCheckCompleted() async {
    final now = DateTime.now();
    await SettingsService.setLastHealthCheckAt(now);
    if (await SettingsService.getNotificationsEnabled()) {
      await NotificationService.scheduleHealthCheckReminder(now);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: context.tr('suggested_herbal_plants'),
      ),
      body: SafeArea(
        child: Consumer<SymptomProvider>(
          builder: (context, provider, child) {
            if (provider.isLoadingRecommendations) {
              return const LoadingWidget();
            }

            final plants = provider.getRecommendedPlants();
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('suggested_plants_based_on_symptoms'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (provider.selectedSymptoms.isNotEmpty) ...[
                          Text(
                            context.tr('your_selected_symptoms_colon'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: provider.selectedSymptoms
                                .map((symptom) => Chip(
                                      label: Text('✓ ${symptom.name}'),
                                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                                      labelStyle: TextStyle(color: AppTheme.primary),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                        _buildSortOptions(context, provider),
                        const SizedBox(height: 16),
                        _buildFilters(context, provider),
                        const SizedBox(height: 24),
                        if (provider.recommendationsError != null)
                          _buildErrorState(context, provider)
                        else if (plants.isEmpty)
                          _buildEmptyState(context)
                        else
                          ...plants.map((plant) => _buildPlantCard(context, plant)),
                        const SizedBox(height: 24),
                        _buildDisclaimer(context),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSortOptions(BuildContext context, SymptomProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('sort_by'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: SortOption.values.map((option) {
              final isSelected = provider.sortOption == option;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_getSortLabel(context, option)),
                  selected: isSelected,
                  onSelected: (_) {
                    provider.setSortOption(option);
                  },
                  selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppTheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.primary : null,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppTheme.primary : Colors.grey.shade300,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context, SymptomProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('filters_colon'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.filterOptions.map((filter) {
            final isSelected = provider.activeFilters.contains(filter);
            return FilterChip(
              label: Text(_getFilterLabel(context, filter)),
              selected: isSelected,
              onSelected: (_) {
                provider.toggleFilter(filter);
              },
              selectedColor: AppTheme.primary.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primary : null,
              ),
              side: BorderSide(
                color: isSelected ? AppTheme.primary : Colors.grey.shade300,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.eco_outlined,
      title: context.tr('no_plants_for_symptoms'),
      subtitle: '',
      action: CustomButton(
        text: context.tr('choose_different_symptoms'),
        onPressed: () {
          // A single context.pop() only lands back on Health Check (the
          // screen pushed just before this one, for both the /symptoms and
          // /describe entry points) -- not actually "choosing different
          // symptoms" as promised. go('/symptoms') takes the user straight
          // to the symptom picker and clears the now-stale recommendation
          // off the stack, regardless of which entry point they came from.
          // This empty state only shows up when the current selection
          // produced zero results, so clear it too -- otherwise the user
          // would land back on the picker with that same losing combination
          // still checked.
          Provider.of<SymptomProvider>(context, listen: false).clearSymptoms();
          context.go('/symptoms');
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, SymptomProvider provider) {
    return EmptyStateWidget(
      icon: Icons.wifi_off_rounded,
      title: provider.recommendationsError ?? context.tr('something_went_wrong'),
      subtitle: context.tr('check_connection_retry'),
      action: CustomButton(
        text: context.tr('retry'),
        onPressed: () => provider.fetchRecommendations(),
      ),
    );
  }

  Widget _buildPlantCard(BuildContext context, Plant plant) {
    return RecommendationCard(
      plant: plant,
      onViewDetails: () {
        context.push('/plant-details', extra: plant);
      },
    );
  }

  Widget _buildDisclaimer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.yellow.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.yellow.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('educational_purpose_only'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('herbai_educational_disclaimer'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange.shade800,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _getSortLabel(BuildContext context, SortOption option) {
    switch (option) {
      case SortOption.bestMatch:
        return context.tr('sort_best_match');
      case SortOption.highestRated:
        return context.tr('sort_highest_rated');
      case SortOption.alphabetical:
        return context.tr('sort_alphabetical');
    }
  }

  String _getFilterLabel(BuildContext context, String filter) {
    switch (filter) {
      case 'Commonly Available':
        return context.tr('filter_commonly_available');
      case 'Easy to Prepare':
        return context.tr('filter_easy_to_prepare');
      default:
        return filter;
    }
  }
}
