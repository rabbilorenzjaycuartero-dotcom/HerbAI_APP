import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/plant_provider.dart';
import '../models/plant_model.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/plant_card.dart';
import '../widgets/section_header.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_widget.dart';
import '../core/app_theme.dart';
import '../core/context_extensions.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Plant> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query, PlantProvider provider) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = provider.searchPlants(query);
    });

    if (_searchResults.isNotEmpty) {
      provider.addSearch(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plantProvider = Provider.of<PlantProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(
        showBackButton: false,
      ),
      body: SafeArea(
        child: plantProvider.isLoading
            ? const LoadingWidget()
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CustomSearchBar(
                      controller: _searchController,
                      onChanged: (query) => _handleSearch(query, plantProvider),
                      onSubmitted: (query) => _handleSearch(query, plantProvider),
                    ),
                  ),
                  Expanded(
                    child: _isSearching
                        ? _buildSearchResults(context)
                        : _buildRecentSearches(context, plantProvider),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRecentSearches(BuildContext context, PlantProvider plantProvider) {
    if (plantProvider.recentSearches.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search,
        title: context.tr('no_recent_searches'),
        subtitle: context.tr('start_searching_blurb'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: context.tr('recent_searches'),
            actionText: context.tr('clear'),
            onActionTap: () {
              plantProvider.clearRecentSearches();
            },
          ),
          const SizedBox(height: 16),
          ...plantProvider.recentSearches.map((search) => ListTile(
                leading: const Icon(Icons.history),
                title: Text(search),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _searchController.text = search;
                  _handleSearch(search, plantProvider);
                },
              )),
          const SizedBox(height: 32),
          SectionHeader(title: context.tr('popular_searches')),
          const SizedBox(height: 16),
          ...plantProvider.plants.take(5).map((plant) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryLight,
                  child: const Icon(Icons.eco, color: Colors.white),
                ),
                title: Text(plant.name),
                subtitle: Text(plant.scientificName),
                onTap: () {
                  context.push('/plant-details', extra: plant);
                },
              )),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    if (_searchResults.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off,
        title: context.tr('no_results_found'),
        subtitle: context.tr('try_different_keywords'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final plant = _searchResults[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: PlantCard(
            plant: plant,
            onTap: () {
              context.push('/plant-details', extra: plant);
            },
          ),
        );
      },
    );
  }
}
