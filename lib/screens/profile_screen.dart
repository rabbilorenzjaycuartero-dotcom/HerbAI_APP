import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/plant_provider.dart';
import '../widgets/custom_appbar.dart';
import '../core/app_theme.dart';
import '../services/firebase_auth_service.dart';
import '../services/rating_service.dart';
import '../services/settings_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _reviewCount;
  int? _searchCount;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final uid = FirebaseAuthService.currentUser?.uid;
    final results = await Future.wait([
      if (uid != null) RatingService.getUserReviewCount(uid) else Future.value(0),
      SettingsService.getSearchCount(),
    ]);
    if (!mounted) return;
    setState(() {
      _reviewCount = results[0];
      _searchCount = results[1];
    });
  }

  Future<void> _handleEditProfile() async {
    await context.push('/edit-profile');
    // Picks up a changed name/photo immediately instead of only after
    // leaving and reopening this screen.
    await FirebaseAuthService.refreshCurrentUser();
    if (mounted) setState(() {});
  }

  Future<void> _handleLogout() async {
    debugPrint('Logout initiated from profile screen');
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      debugPrint('Logout confirmed, signing out...');
      await FirebaseAuthService.signOut();
      debugPrint('Logout completed, navigating to login');
      if (mounted) {
        context.go('/login');
      }
    } else {
      debugPrint('Logout cancelled');
    }
  }

  @override
  Widget build(BuildContext context) {
    final plantProvider = Provider.of<PlantProvider>(context);
    final user = FirebaseAuthService.currentUser;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Profile',
        showBackButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              _buildProfileHeader(plantProvider, user),
              const SizedBox(height: 32),
              _buildStats(plantProvider),
              const SizedBox(height: 32),
              _buildMenuItems(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(PlantProvider plantProvider, AuthUser? user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: AppTheme.primaryLight,
          child: const Icon(
            Icons.person,
            size: 60,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user?.displayName ?? 'Herbal Enthusiast',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user?.email ?? '',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStats(PlantProvider plantProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('Favorites', plantProvider.favorites.length),
        _buildStatItem('Reviews', _reviewCount),
        _buildStatItem('Searches', _searchCount),
      ],
    );
  }

  Widget _buildStatItem(String label, int? count) {
    return Column(
      children: [
        Text(
          count?.toString() ?? '—',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.edit,
            title: 'Edit Profile',
            onTap: _handleEditProfile,
          ),
          _buildMenuItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              context.push('/settings');
            },
          ),
          _buildMenuItem(
            icon: Icons.info,
            title: 'About HERBAI',
            onTap: () {
              context.push('/about');
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: _handleLogout,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : AppTheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
