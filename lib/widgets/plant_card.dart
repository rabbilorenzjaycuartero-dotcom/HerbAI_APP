import 'package:flutter/material.dart';
import '../models/plant_model.dart';
import '../core/app_theme.dart';
import 'rating_widget.dart';

class PlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback? onTap;
  final bool isHorizontal;

  const PlantCard({
    super.key,
    required this.plant,
    this.onTap,
    this.isHorizontal = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: isHorizontal
            ? SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16.0),
                      ),
                      child: _buildImage(height: 120),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plant.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            plant.scientificName,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          RatingWidget(rating: plant.rating),
                          const SizedBox(height: 4),
                          Text(
                            plant.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16.0),
                    ),
                    child: _buildImage(height: 140),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plant.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          plant.scientificName,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        RatingWidget(rating: plant.rating),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildImage({required double height}) {
    // Image.network throws synchronously (before errorBuilder can catch it)
    // when given an empty URL, which is the neutral default for herbs with
    // no gathered image data -- so an empty url skips straight to fallback.
    if (plant.imageUrl.isEmpty) {
      return Container(
        height: height,
        color: AppTheme.primaryLight,
        child: const Icon(Icons.eco, size: 48, color: Colors.white),
      );
    }
    return Image.network(
      plant.imageUrl,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height,
          color: AppTheme.primaryLight,
          child: const Icon(Icons.eco, size: 48, color: Colors.white),
        );
      },
    );
  }
}
