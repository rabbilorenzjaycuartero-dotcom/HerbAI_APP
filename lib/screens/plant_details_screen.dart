import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/plant_model.dart';
import '../providers/plant_provider.dart';
import '../core/app_theme.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/plant_rating_section.dart';
import '../widgets/plant_reviews_section.dart';
import '../widgets/source_webview_screen.dart';
import '../widgets/zoomable_image_viewer.dart';

class PlantDetailsScreen extends StatefulWidget {
  final Plant plant;

  const PlantDetailsScreen({
    super.key,
    required this.plant,
  });

  @override
  State<PlantDetailsScreen> createState() => _PlantDetailsScreenState();
}

class _PlantDetailsScreenState extends State<PlantDetailsScreen> {
  Plant get plant => widget.plant;

  // Bumped whenever a review is posted, so PlantReviewsSection (keyed on
  // this) remounts and re-fetches instead of only showing the new review
  // after the user leaves and reopens this screen.
  int _reviewsRefreshToken = 0;

  void _handleShare() {
    final parts = [
      plant.scientificName.isNotEmpty
          ? '${plant.name} (${plant.scientificName})'
          : plant.name,
      if (plant.description.isNotEmpty) plant.description,
      if (plant.medicinalUses.isNotEmpty)
        'Medicinal Uses:\n${plant.medicinalUses.map((u) => '• $u').join('\n')}',
      if (plant.preparationMethods.isNotEmpty)
        'Preparation Methods:\n${plant.preparationMethods.map((m) => '• $m').join('\n')}',
      if (plant.safetyWarnings.isNotEmpty)
        'Safety Warnings:\n${plant.safetyWarnings.map((w) => '• $w').join('\n')}',
      if (plant.sourceUrl.isNotEmpty) 'Source: ${plant.sourceUrl}',
      'Shared via HERBAI',
    ];
    Share.share(parts.join('\n\n'));
  }

  @override
  Widget build(BuildContext context) {
    final plantProvider = Provider.of<PlantProvider>(context);

    return Scaffold(
      appBar: CustomAppBar(
        actions: [
          IconButton(
            icon: Icon(
              plantProvider.isFavorite(plant)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: plantProvider.isFavorite(plant) ? Colors.red : null,
            ),
            onPressed: () {
              plantProvider.toggleFavorite(plant);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _handleShare,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlantImage(context),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPlantHeader(),
                  const SizedBox(height: 8),
                  PlantRatingSection(
                    plantId: plant.id,
                    onReviewPosted: () {
                      setState(() => _reviewsRefreshToken++);
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildDescription(),
                  const SizedBox(height: 24),
                  _buildSection('Medicinal Uses', plant.medicinalUses, Icons.healing),
                  const SizedBox(height: 24),
                  _buildSection('Preparation Methods', plant.preparationMethods, Icons.medical_services),
                  const SizedBox(height: 24),
                  if (plant.conditionWarnings.isNotEmpty) ...[
                    _buildConditionWarnings(),
                    const SizedBox(height: 24),
                  ],
                  _buildSafetyWarnings(),
                  const SizedBox(height: 24),
                  _buildEthnobotanicalInfo(),
                  const SizedBox(height: 24),
                  PlantReviewsSection(
                    key: ValueKey(_reviewsRefreshToken),
                    plantId: plant.id,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantImage(BuildContext context) {
    // Image.network throws synchronously (before errorBuilder can catch it)
    // when given an empty URL, which is the neutral default for herbs with
    // no gathered image data -- so an empty url skips straight to fallback.
    final fallback = Container(
      height: 300,
      color: AppTheme.primaryLight,
      child: const Center(
        child: Icon(Icons.eco, size: 100, color: Colors.white),
      ),
    );
    return Stack(
      children: [
        if (plant.imageUrl.isEmpty)
          fallback
        else
          GestureDetector(
            onTap: () => ZoomableImageViewer.show(context, plant.imageUrl),
            child: Image.network(
              plant.imageUrl,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallback,
            ),
          ),
      ],
    );
  }

  Widget _buildPlantHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          plant.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          plant.scientificName,
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          plant.description,
          style: TextStyle(
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<String> items, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 12),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildConditionWarnings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.priority_high_rounded, color: Colors.red),
            const SizedBox(width: 8),
            const Text(
              'Relevant to You',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...plant.conditionWarnings.map((warning) {
          final color = warning.severity == 'avoid' ? Colors.red.shade700 : Colors.orange.shade800;
          return Card(
            color: color.withValues(alpha: 0.08),
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      warning.note,
                      style: TextStyle(height: 1.4, color: color),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSafetyWarnings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 8),
            const Text(
              'Safety Warnings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.orange.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: plant.safetyWarnings.map((warning) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      '• $warning',
                      style: const TextStyle(height: 1.4),
                    ),
                  )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEthnobotanicalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Traditional Knowledge',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: AppTheme.primary.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant.ethnobotanicalInfo,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (plant.sourceUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => SourceWebviewScreen.show(context, plant.sourceUrl),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.open_in_new_rounded, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'View source',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

}
