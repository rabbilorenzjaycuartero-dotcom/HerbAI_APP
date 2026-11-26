import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/symptom_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/doh_approved_badge.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/rating_widget.dart';
import '../models/plant_model.dart';
import '../core/app_theme.dart';
import '../core/context_extensions.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';

/// Results dashboard: curved green header with the searched symptoms and the
/// result count, sort chips, the #1 herb as a large card, the rest as
/// compact rows, and the educational disclaimer. Used both as the Recommend
/// tab and as the /recommendations route after a search.
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
      backgroundColor: AppTheme.background,
      body: Consumer<SymptomProvider>(
        builder: (context, provider, child) {
          final plants = provider.isLoadingRecommendations ? <Plant>[] : provider.getRecommendedPlants();
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, provider, plants.length),
                Transform.translate(
                  offset: const Offset(0, -22),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (provider.hasSelectedSymptoms) ...[
                          _buildSortOptions(context, provider),
                          const SizedBox(height: 16),
                        ],
                        if (provider.isLoadingRecommendations)
                          const Padding(
                            padding: EdgeInsets.only(top: 60),
                            child: LoadingWidget(),
                          )
                        else if (!provider.hasSelectedSymptoms)
                          _buildNoSearchYet(context)
                        else if (provider.recommendationsError != null)
                          _buildErrorState(context, provider)
                        else if (plants.isEmpty)
                          _buildEmptyState(context)
                        else ...[
                          _buildTopCard(context, provider, plants.first),
                          if (plants.length > 1) ...[
                            const SizedBox(height: 20),
                            Text(
                              context.tr('more_suggestions'),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            for (var i = 1; i < plants.length; i++)
                              _buildCompactCard(context, provider, plants[i], i + 1),
                          ],
                        ],
                        const SizedBox(height: 20),
                        _buildDisclaimer(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------- header

  Widget _buildHeader(BuildContext context, SymptomProvider provider, int count) {
    final topInset = MediaQuery.paddingOf(context).top;
    final canPop = Navigator.of(context).canPop();
    return ClipPath(
      clipper: _HeaderCurveClipper(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20, topInset + (canPop ? 4 : 20), 20, 52),
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
              top: -10,
              child: Transform.rotate(
                angle: -0.5,
                child: Icon(Icons.eco, size: 120, color: Colors.white.withValues(alpha: 0.09)),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (canPop)
                  IconButton(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                Text(
                  context.tr('your_results'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.hasSelectedSymptoms
                      ? (provider.isLoadingRecommendations
                          ? context.tr('finding_herbs')
                          : '$count ${context.tr(count == 1 ? 'herb_found' : 'herbs_found')}')
                      : context.tr('suggested_plants_based_on_symptoms'),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 14),
                ),
                if (provider.selectedSymptoms.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final symptom in provider.selectedSymptoms)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            symptom.name,
                            style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOptions(BuildContext context, SymptomProvider provider) {
    return Material(
      color: AppTheme.background,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 8),
                child: Icon(Icons.sort_rounded, size: 20, color: AppTheme.textSecondary),
              ),
              for (final option in SortOption.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(_getSortLabel(context, option)),
                    selected: provider.sortOption == option,
                    onSelected: (_) => provider.setSortOption(option),
                    selectedColor: AppTheme.primary,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: provider.sortOption == option ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: provider.sortOption == option ? AppTheme.primary : Colors.grey.shade300,
                    ),
                    shape: const StadiumBorder(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- cards

  /// Symptoms this herb helps with, the ones the user searched for first.
  List<String> _orderedSymptoms(SymptomProvider provider, Plant plant) {
    final searched = provider.selectedSymptoms.map((s) => s.name.toLowerCase()).toSet();
    final matched = plant.symptomsHelped.where((s) => searched.contains(s.toLowerCase()));
    final others = plant.symptomsHelped.where((s) => !searched.contains(s.toLowerCase()));
    return [...matched, ...others];
  }

  bool _isSearched(SymptomProvider provider, String symptom) =>
      provider.selectedSymptoms.any((s) => s.name.toLowerCase() == symptom.toLowerCase());

  Widget _buildTopCard(BuildContext context, SymptomProvider provider, Plant plant) {
    final symptoms = _orderedSymptoms(provider, plant).take(6).toList();
    final topLabel = provider.sortOption == SortOption.bestMatch
        ? context.tr('top_match')
        : _getSortLabel(context, provider.sortOption);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/plant-details', extra: plant),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _plantImage(plant, height: 170, width: double.infinity, radius: 0, iconSize: 64),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: Colors.black87),
                          const SizedBox(width: 4),
                          Text(
                            topLabel.toUpperCase(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plant.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(
                      plant.scientificName,
                      style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        RatingWidget(rating: plant.rating),
                        const SizedBox(width: 6),
                        Text('(${plant.reviewCount})', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        if (plant.isDohRecognized) ...[
                          const SizedBox(width: 10),
                          const Flexible(child: DohApprovedBadge(size: 14)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(context.tr('may_help_with'),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [for (final s in symptoms) _symptomChip(s, highlighted: _isSearched(provider, s))],
                    ),
                    if (plant.conditionWarnings.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...plant.conditionWarnings.map(_buildWarning),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: context.tr('view_details'),
                        onPressed: () => context.push('/plant-details', extra: plant),
                        borderRadius: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context, SymptomProvider provider, Plant plant, int rank) {
    final symptoms = _orderedSymptoms(provider, plant).take(3).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/plant-details', extra: plant),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _plantImage(plant, height: 78, width: 78, radius: 14, iconSize: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              plant.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text('#$rank',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                        ],
                      ),
                      Text(
                        plant.scientificName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (final s in symptoms) _symptomChip(s, highlighted: _isSearched(provider, s), small: true),
                        ],
                      ),
                      if (plant.isDohRecognized || plant.conditionWarnings.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        // Wrap (not Row): the DOH badge and the precaution
                        // note go on separate lines when they don't fit.
                        Wrap(
                          spacing: 10,
                          runSpacing: 4,
                          children: [
                            if (plant.isDohRecognized) const DohApprovedBadge(size: 12),
                            if (plant.conditionWarnings.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange.shade800),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      context.tr('has_precaution'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 11.5, color: Colors.orange.shade800),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(top: 28),
                  child: Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _symptomChip(String label, {required bool highlighted, bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 10, vertical: small ? 3 : 5),
      decoration: BoxDecoration(
        color: highlighted ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        highlighted ? '✓ $label' : label,
        style: TextStyle(
          fontSize: small ? 11 : 12,
          fontWeight: FontWeight.w600,
          color: highlighted ? Colors.white : AppTheme.primary,
        ),
      ),
    );
  }

  Widget _plantImage(Plant plant,
      {required double height, required double width, required double radius, required double iconSize}) {
    // Image.network throws synchronously for an empty URL (herbs with no
    // gathered photo), so those go straight to the fallback.
    final fallback = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(Icons.eco, size: iconSize, color: Colors.white),
    );
    if (plant.imageUrl.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        plant.imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }

  Widget _buildWarning(ConditionWarning warning) {
    final color = warning.severity == 'avoid' ? Colors.red.shade700 : Colors.orange.shade800;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(warning.note, style: TextStyle(fontSize: 12, height: 1.4, color: color))),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- states

  /// Shown when the Recommend tab is opened before any search.
  Widget _buildNoSearchYet(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(22),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.eco_rounded, size: 40, color: AppTheme.primary),
          ),
          const SizedBox(height: 14),
          Text(
            context.tr('no_results_yet'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('no_results_yet_subtitle'),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: context.tr('start_herbal_recommendation'),
              icon: Icons.chat_bubble_outline_rounded,
              onPressed: () => context.push('/chat'),
              borderRadius: 30,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: context.tr('select_your_symptoms'),
              icon: Icons.checklist_rounded,
              isOutlined: true,
              onPressed: () => context.push('/symptoms'),
              borderRadius: 30,
            ),
          ),
        ],
      ),
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
          // Back to the chatbot with this losing selection cleared.
          Provider.of<SymptomProvider>(context, listen: false).clearSymptoms();
          context.go('/chat');
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

  Widget _buildDisclaimer(BuildContext context) {
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
                Text(context.tr('educational_purpose_only'), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  context.tr('herbai_educational_disclaimer'),
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                ),
              ],
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
      case SortOption.clinicallyApproved:
        return context.tr('sort_clinically_approved');
    }
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
