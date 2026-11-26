import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/plant_provider.dart';
import '../providers/user_profile_store.dart';
import '../widgets/demographics_fields.dart';
import '../core/app_theme.dart';
import '../core/context_extensions.dart';
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
    // The review count needs Firestore; if the network is down, keep the
    // local search count instead of letting the whole load throw.
    final reviewFuture = uid == null
        ? Future.value(0)
        : RatingService.getUserReviewCount(uid).catchError((Object e) {
            debugPrint('getUserReviewCount failed: $e');
            return 0;
          });
    final results = await Future.wait([reviewFuture, SettingsService.getSearchCount()]);
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
        title: Text(context.tr('logout')),
        content: Text(context.tr('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              context.tr('cancel'),
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.tr('logout'),
              style: const TextStyle(color: Colors.red),
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
      backgroundColor: AppTheme.background,
      body: ListenableBuilder(
        listenable: userProfileStore,
        builder: (context, _) => SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              _buildProfileHeader(context, user),
              Transform.translate(
                offset: const Offset(0, -36),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStats(context, plantProvider),
                      const SizedBox(height: 24),
                      _buildMenuGroup(context.tr('account_section'), [
                        _MenuEntry(Icons.edit_outlined, context.tr('edit_profile'), _handleEditProfile),
                        _MenuEntry(Icons.settings_outlined, context.tr('settings'), () => context.push('/settings')),
                      ]),
                      if (userProfileStore.isAdmin) ...[
                        const SizedBox(height: 18),
                        _buildMenuGroup(context.tr('admin_section'), [
                          _MenuEntry(Icons.bar_chart_rounded, context.tr('reports_title'),
                              () => context.push('/admin/reports')),
                          _MenuEntry(Icons.admin_panel_settings_outlined, context.tr('manage_admins'),
                              () => context.push('/admin/admins')),
                          _MenuEntry(Icons.history_rounded, context.tr('admin_activity_log'),
                              () => context.push('/admin/activity')),
                        ]),
                      ],
                      const SizedBox(height: 18),
                      _buildMenuGroup(context.tr('about_section'), [
                        _MenuEntry(Icons.info_outline, context.tr('about_herbai'), () => context.push('/about')),
                        _MenuEntry(Icons.privacy_tip_outlined, context.tr('privacy_policy'), () => context.push('/privacy')),
                        _MenuEntry(Icons.description_outlined, context.tr('terms_conditions'), () => context.push('/terms')),
                      ]),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _handleLogout,
                          icon: const Icon(Icons.logout_rounded),
                          label: Text(context.tr('logout')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade600,
                            side: BorderSide(color: Colors.red.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          'HerbAI · ${context.tr('version_1_0_0')}',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  Widget _buildProfileHeader(BuildContext context, AuthUser? user) {
    final topInset = MediaQuery.paddingOf(context).top;
    final profile = userProfileStore.profile;
    final initials = _initials(user?.displayName);
    final designation = profile?.designation;
    final designationText = designation == null
        ? null
        : (designation == 'Others' && (profile?.designationOther ?? '').isNotEmpty)
            ? profile!.designationOther!
            : context.tr(designationKey(designation));

    return ClipPath(
      clipper: _HeaderCurveClipper(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20, topInset + 24, 20, 72),
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
              right: -30,
              top: -12,
              child: Transform.rotate(
                angle: -0.5,
                child: Icon(Icons.eco, size: 140, color: Colors.white.withValues(alpha: 0.09)),
              ),
            ),
            Column(
              children: [
                const SizedBox(width: double.infinity),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.white,
                    child: initials.isEmpty
                        ? Icon(Icons.person, size: 46, color: AppTheme.primary)
                        : Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.displayName ?? context.tr('herbal_enthusiast'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? '',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13.5),
                ),
                if (designationText != null || profile?.age != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (designationText != null) _headerChip(Icons.badge_outlined, designationText),
                      if (profile?.age != null)
                        _headerChip(Icons.cake_outlined, '${profile!.age} ${context.tr('years_old')}'),
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

  Widget _headerChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context, PlantProvider plantProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: _buildStatItem(Icons.favorite_rounded, context.tr('favorites'), plantProvider.favorites.length)),
            VerticalDivider(color: AppTheme.textSecondary.withValues(alpha: 0.2), width: 1),
            Expanded(child: _buildStatItem(Icons.star_rounded, context.tr('reviews'), _reviewCount)),
            VerticalDivider(color: AppTheme.textSecondary.withValues(alpha: 0.2), width: 1),
            Expanded(child: _buildStatItem(Icons.search_rounded, context.tr('searches'), _searchCount)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, int? count) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(height: 4),
        Text(
          count?.toString() ?? '—',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary),
        ),
        Text(label, style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildMenuGroup(String title, List<_MenuEntry> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(entries[i].icon, size: 20, color: AppTheme.primary),
                  ),
                  title: Text(entries[i].title, style: const TextStyle(fontWeight: FontWeight.w500)),
                  trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                  onTap: entries[i].onTap,
                ),
                if (i < entries.length - 1)
                  Divider(height: 1, indent: 64, color: AppTheme.textSecondary.withValues(alpha: 0.15)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuEntry {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuEntry(this.icon, this.title, this.onTap);
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
