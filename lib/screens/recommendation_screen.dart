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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Suggested Herbal Plants',
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
                        const Text(
                          '🌿 Suggested Herbal Plants Based on Your Selected Symptoms',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (provider.selectedSymptoms.isNotEmpty) ...[
                          const Text(
                            'Your Selected Symptoms:',
                            style: TextStyle(
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
                        _buildDisclaimer(),
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
        const Text(
          'Sort By:',
          style: TextStyle(
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
                  label: Text(_getSortLabel(option)),
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
        const Text(
          'Filters:',
          style: TextStyle(
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
              label: Text(filter),
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
      title: 'No herbal plants were found for the selected symptoms.',
      subtitle: '',
      action: CustomButton(
        text: 'Choose Different Symptoms',
        onPressed: () {
          // context.pop() throws GoError("There is nothing to pop") when
          // this screen is the bottom of the navigation stack instead of
          // being pushed on top of /symptoms or /describe -- fall back to
          // going home rather than crashing the tap handler.
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, SymptomProvider provider) {
    return EmptyStateWidget(
      icon: Icons.wifi_off_rounded,
      title: provider.recommendationsError ?? 'Something went wrong.',
      subtitle: 'Check your connection and try again.',
      action: CustomButton(
        text: 'Retry',
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

  Widget _buildDisclaimer() {
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
              Text(
                'Educational Purpose Only',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'HERBIA provides educational information based on ethnobotanical knowledge. This application does not replace professional medical advice. Consult a licensed healthcare professional for proper diagnosis and treatment.',
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

  String _getSortLabel(SortOption option) {
    switch (option) {
      case SortOption.bestMatch:
        return 'Best Match';
      case SortOption.highestRated:
        return 'Highest Rated';
      case SortOption.alphabetical:
        return 'Alphabetical';
    }
  }
}
