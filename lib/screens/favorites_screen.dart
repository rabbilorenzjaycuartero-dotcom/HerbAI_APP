import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/plant_model.dart';
import '../providers/plant_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/rating_widget.dart';
import '../core/app_theme.dart';
import '../core/context_extensions.dart';

/// Saved herbs: curved green header with the count, a search inside the
/// favorites, and a 2-column grid. Removing a herb (heart button) shows an
/// UNDO snackbar.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _remove(PlantProvider provider, Plant plant) {
    provider.toggleFavorite(plant);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${plant.name} ${context.trRead('removed_from_favorites')}'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: context.trRead('undo'),
          onPressed: () {
            if (!provider.isFavorite(plant)) provider.toggleFavorite(plant);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Consumer<PlantProvider>(
        builder: (context, provider, child) {
          final favorites = provider.favorites;
          final shown = _query.isEmpty
              ? favorites
              : favorites
                  .where((p) =>
                      p.name.toLowerCase().contains(_query) || p.scientificName.toLowerCase().contains(_query))
                  .toList();
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, favorites.length),
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: favorites.isEmpty
                          ? _buildEmptyState(context)
                          : Column(
                              children: [
                                _buildSearchBar(context),
                                const SizedBox(height: 16),
                                if (shown.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 40),
                                    child: Text(
                                      context.tr('no_favorites_match'),
                                      style: TextStyle(color: AppTheme.textSecondary),
                                    ),
                                  )
                                else
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: EdgeInsets.zero,
                                    itemCount: shown.length,
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      mainAxisExtent: 236,
                                    ),
                                    itemBuilder: (context, index) => _FavoriteCard(
                                      plant: shown[index],
                                      onTap: () => context.push('/plant-details', extra: shown[index]),
                                      onRemove: () => _remove(provider, shown[index]),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    final topInset = MediaQuery.paddingOf(context).top;
    return ClipPath(
      clipper: _HeaderCurveClipper(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20, topInset + 20, 20, 60),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B5E20), AppTheme.primary, Color(0xFF43A047)],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -10,
              top: -6,
              child: Icon(Icons.favorite_rounded, size: 110, color: Colors.white.withValues(alpha: 0.10)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('my_favorites'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  count == 0
                      ? context.tr('start_adding_favorites')
                      : '$count ${context.tr(count == 1 ? 'saved_herb' : 'saved_herbs')}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Material(
      color: AppTheme.background,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(18),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
        decoration: InputDecoration(
          hintText: context.tr('search_favorites_hint'),
          hintStyle: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.7)),
          prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primary),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: AppTheme.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppTheme.background,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: Icon(Icons.favorite_border_rounded, size: 42, color: Colors.red.shade400),
          ),
          const SizedBox(height: 14),
          Text(
            context.tr('no_favorites_yet'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('favorites_empty_help'),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: context.tr('browse_all_plants'),
              icon: Icons.menu_book_outlined,
              onPressed: () => context.push('/search'),
              borderRadius: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteCard({required this.plant, required this.onTap, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _image(),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onRemove,
                        child: Padding(
                          padding: const EdgeInsets.all(7),
                          child: Icon(Icons.favorite_rounded, size: 20, color: Colors.red.shade500),
                        ),
                      ),
                    ),
                  ),
                  if (plant.isDohRecognized)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'DOH',
                          style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      plant.scientificName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 6),
                    RatingWidget(rating: plant.rating, starSize: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _image() {
    // Image.network throws synchronously for an empty URL, so herbs with no
    // photo go straight to the fallback.
    final fallback = Container(
      height: 130,
      width: double.infinity,
      color: AppTheme.primaryLight,
      child: const Icon(Icons.eco, size: 48, color: Colors.white),
    );
    if (plant.imageUrl.isEmpty) return fallback;
    return Image.network(
      plant.imageUrl,
      height: 130,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}

class _HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final h = size.height;
    final w = size.width;
    return Path()
      ..lineTo(0, h - 36)
      ..quadraticBezierTo(w * 0.3, h, w * 0.6, h - 20)
      ..quadraticBezierTo(w * 0.85, h - 34, w, h - 10)
      ..lineTo(w, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
