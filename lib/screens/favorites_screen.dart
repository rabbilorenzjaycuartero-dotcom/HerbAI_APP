import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/plant_provider.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/plant_card.dart';
import '../core/context_extensions.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: context.tr('favorites'),
        showBackButton: false,
      ),
      body: Consumer<PlantProvider>(
        builder: (context, plantProvider, child) {
          if (plantProvider.favorites.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.favorite_border,
              title: context.tr('no_favorites_yet'),
              subtitle: context.tr('start_adding_favorites'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: plantProvider.favorites.length,
            itemBuilder: (context, index) {
              final plant = plantProvider.favorites[index];
              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: PlantCard(
                      plant: plant,
                      onTap: () {
                        context.push('/plant-details', extra: plant);
                      },
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        plantProvider.toggleFavorite(plant);
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
