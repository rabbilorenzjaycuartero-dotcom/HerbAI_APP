import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/plant_model.dart';
import '../providers/plant_provider.dart';
import '../providers/symptom_provider.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/plant_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/custom_button.dart';
import '../core/app_theme.dart';
import '../core/context_extensions.dart';

/// Dashboard-style Home: a curved green header (greeting + search), the two
/// ways to get recommendations (chatbot and symptom checklist), a featured
/// plants carousel, the user's latest recommendations, and the educational
/// disclaimer. Same visual language as the Login/Create Account screens.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final plantProvider = Provider.of<PlantProvider>(context);
    final symptomProvider = Provider.of<SymptomProvider>(context);

    if (plantProvider.isLoading) {
      return const Scaffold(body: LoadingWidget());
    }

    final featuredPlants = plantProvider.getFeaturedPlants().take(10).toList();
    final recommendedPlants = symptomProvider.getRecommendedPlants().take(3).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(context),
                    const SizedBox(height: 24),
                    _sectionTitle(context, context.tr('how_can_we_help')),
                    const SizedBox(height: 12),
                    _buildChatbotCard(context),
                    const SizedBox(height: 12),
                    _buildSelectSymptomsCard(context),
                    const SizedBox(height: 28),
                    _sectionTitle(
                      context,
                      context.tr('featured_plants'),
                      action: context.tr('see_all'),
                      onAction: () => context.push('/search'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('featured_plants_subtitle'),
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -16),
              child: _buildFeaturedCarousel(context, featuredPlants),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _sectionTitle(context, context.tr('your_recommendations')),
                  const SizedBox(height: 12),
                  if (recommendedPlants.isEmpty)
                    _buildNoRecommendations(context)
                  else
                    ...recommendedPlants.map(
                      (plant) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PlantCard(
                          plant: plant,
                          onTap: () => context.push('/plant-details', extra: plant),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _buildDisclaimerCard(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greetingKey() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'good_morning';
    if (hour < 18) return 'good_afternoon';
    return 'good_evening';
  }

  Widget _buildHeader(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final name = FirebaseAuthService.currentUser?.displayName?.trim();
    final firstName = (name == null || name.isEmpty) ? null : name.split(' ').first;

    return ClipPath(
      clipper: _HeaderCurveClipper(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20, topInset + 20, 20, 64),
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
              right: -24,
              top: -18,
              child: Transform.rotate(
                angle: -0.5,
                child: Icon(Icons.eco, size: 130, color: Colors.white.withValues(alpha: 0.09)),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(_greetingKey()),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        firstName != null ? '$firstName 👋' : context.tr('welcome_to_herbai'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr('discover_herbal_medicine'),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.35),
                      ),
                    ],
                  ),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/search'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: AppTheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.tr('search_herbs_hint'),
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                ),
              ),
              Icon(Icons.tune_rounded, color: AppTheme.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, {String? action, VoidCallback? onAction}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(action, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  /// Primary action: the AI chatbot (panel revision).
  Widget _buildChatbotCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.82)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/chat'),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded, size: 28, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('start_herbal_recommendation'),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('select_symptoms_ai_blurb'),
                        style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.9), height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(Icons.arrow_forward_rounded, size: 18, color: AppTheme.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The original pick-from-a-list flow.
  Widget _buildSelectSymptomsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/symptoms'),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.checklist_rounded, size: 28, color: AppTheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('select_your_symptoms'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('select_symptoms_card_subtitle'),
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCarousel(BuildContext context, List<Plant> featuredPlants) {
    if (featuredPlants.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(context.tr('no_plants_yet'), style: TextStyle(color: AppTheme.textSecondary)),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: 292,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        itemCount: featuredPlants.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          final plant = featuredPlants[index];
          return PlantCard(
            plant: plant,
            onTap: () => context.push('/plant-details', extra: plant),
          );
        },
      ),
    );
  }

  Widget _buildNoRecommendations(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.recommend_outlined, size: 44, color: AppTheme.primary.withValues(alpha: 0.6)),
          const SizedBox(height: 10),
          Text(
            context.tr('no_recommendations_yet'),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: context.tr('start_now'),
              onPressed: () => context.push('/chat'),
              borderRadius: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryLight.withValues(alpha: AppTheme.background == AppTheme.darkBackground ? 0.15 : 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.health_and_safety_outlined, color: Colors.orange.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('educational_purpose_only'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('home_health_tip'),
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final h = size.height;
    final w = size.width;
    return Path()
      ..lineTo(0, h - 40)
      ..quadraticBezierTo(w * 0.3, h, w * 0.6, h - 22)
      ..quadraticBezierTo(w * 0.85, h - 38, w, h - 12)
      ..lineTo(w, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
