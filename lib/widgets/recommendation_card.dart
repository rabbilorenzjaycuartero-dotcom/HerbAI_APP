import 'package:flutter/material.dart';
import '../models/plant_model.dart';
import '../core/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/rating_widget.dart';

class RecommendationCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onViewDetails;

  const RecommendationCard({
    super.key,
    required this.plant,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildImage(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🌿 ${plant.name}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        plant.scientificName,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RatingWidget(rating: plant.rating),
                      const SizedBox(height: 4),
                      Text(
                        '${plant.reviewCount} reviews',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection('May Help With:', plant.symptomsHelped),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildBadge('Availability', plant.availability.label,
                    plant.availability.color),
                const SizedBox(width: 12),
              ],
            ),
            if (plant.conditionWarnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildConditionWarnings(),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'View Details',
                onPressed: onViewDetails,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    // Image.network throws synchronously (before errorBuilder can catch it)
    // when given an empty URL, which is the neutral default for herbs with
    // no gathered image data -- so an empty url skips straight to fallback.
    final fallback = Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.eco, size: 40, color: Colors.white),
    );
    if (plant.imageUrl.isEmpty) return fallback;
    return Image.network(
      plant.imageUrl,
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map((item) => Chip(
                    label: Text(
                      '✓ $item',
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      color: AppTheme.primary,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionWarnings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: plant.conditionWarnings.map((warning) {
        final color = warning.severity == 'avoid' ? Colors.red.shade700 : Colors.orange.shade800;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  warning.note,
                  style: TextStyle(fontSize: 12, height: 1.4, color: color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

}
