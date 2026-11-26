import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/search_screen.dart';
import '../screens/plant_details_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/about_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/terms_conditions_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/symptom_selection_screen.dart';
import '../screens/health_check_screen.dart';
import '../screens/complete_profile_screen.dart';
import '../screens/admin_reports_screen.dart';
import '../screens/manage_admins_screen.dart';
import '../screens/admin_activity_screen.dart';
import '../screens/recommendation_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/reset_password_success_screen.dart';
import '../screens/email_verification_screen.dart';
import '../screens/main_dashboard.dart';
import '../services/firebase_auth_service.dart';
import '../models/plant_model.dart';
import '../providers/user_profile_store.dart';

final ValueNotifier<bool> authStateNotifier = ValueNotifier<bool>(false);

void listenToAuthChanges() {
  // FirebaseAuthService.authStateChanges() touches FirebaseAuth.instance,
  // which throws synchronously (not just as a stream error) if Firebase
  // failed to initialize. This runs before runApp() in main(), so an
  // unguarded throw here would stop the app from ever rendering instead of
  // degrading gracefully like the rest of the auth flow does.
  try {
    FirebaseAuthService.authStateChanges().listen((user) {
      authStateNotifier.value = !authStateNotifier.value;
      // Age/designation + admin flag for the profile/report redirects below.
      userProfileStore.loadFor(user?.uid);
    });
  } catch (error, stackTrace) {
    debugPrint('Failed to listen to auth state changes: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

final GoRouter router = GoRouter(
  initialLocation: '/splash',
  refreshListenable: Listenable.merge([authStateNotifier, userProfileStore]),
  redirect: (context, state) {
    final user = FirebaseAuthService.currentUser;
    final isPublicRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register' ||
        state.matchedLocation == '/forgot-password' ||
        state.matchedLocation == '/reset-password-success' ||
        state.matchedLocation == '/splash';

    if (user == null) {
      return isPublicRoute ? null : '/login';
    }

    if (!user.emailVerified) {
      return state.matchedLocation == '/verify-email' ||
              state.matchedLocation == '/splash'
          ? null
          : '/verify-email';
    }

    // Accounts made before Age/Designation were collected complete their
    // profile once (needed for the admin usage reports).
    if (userProfileStore.needsProfile) {
      return state.matchedLocation == '/complete-profile' ? null : '/complete-profile';
    }
    if (state.matchedLocation.startsWith('/admin') && !userProfileStore.isAdmin) {
      return '/';
    }

    return isPublicRoute ||
            state.matchedLocation == '/verify-email' ||
            state.matchedLocation == '/complete-profile'
        ? '/'
        : null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/reset-password-success',
      name: 'reset-password-success',
      builder: (context, state) => const ResetPasswordSuccessScreen(),
    ),
    GoRoute(
      path: '/verify-email',
      name: 'verify-email',
      builder: (context, state) => const EmailVerificationScreen(),
    ),
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const MainDashboard(),
    ),
    GoRoute(
      path: '/chat',
      name: 'chat',
      builder: (context, state) => const ChatScreen(),
    ),
    // The original pick-from-a-list flow, kept alongside the chatbot.
    GoRoute(
      path: '/symptoms',
      name: 'symptoms',
      builder: (context, state) => const SymptomSelectionScreen(),
    ),
    GoRoute(
      path: '/health-check',
      name: 'health-check',
      builder: (context, state) => const HealthCheckScreen(),
    ),
    GoRoute(
      path: '/complete-profile',
      name: 'complete-profile',
      builder: (context, state) => const CompleteProfileScreen(),
    ),
    GoRoute(
      path: '/admin/reports',
      name: 'admin-reports',
      builder: (context, state) => const AdminReportsScreen(),
    ),
    GoRoute(
      path: '/admin/admins',
      name: 'admin-admins',
      builder: (context, state) => const ManageAdminsScreen(),
    ),
    GoRoute(
      path: '/admin/activity',
      name: 'admin-activity',
      builder: (context, state) => const AdminActivityScreen(),
    ),
    GoRoute(
      path: '/recommendations',
      name: 'recommendations',
      builder: (context, state) => const RecommendationScreen(),
    ),
    GoRoute(
      path: '/search',
      name: 'search',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/plant-details',
      name: 'plant-details',
      builder: (context, state) {
        final plant = state.extra as Plant;
        return PlantDetailsScreen(plant: plant);
      },
    ),
    GoRoute(
      path: '/favorites',
      name: 'favorites',
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      name: 'edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/about',
      name: 'about',
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      path: '/privacy',
      name: 'privacy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: '/terms',
      name: 'terms',
      builder: (context, state) => const TermsConditionsScreen(),
    ),
  ],
);
