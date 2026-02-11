import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_reminder_fixed/features/settings/permissions_screen.dart';
import 'package:med_reminder_fixed/features/settings/settings_screen.dart';

import '../providers/providers.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/auth/signin_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/home/home_screen.dart';
import '../features/add_medicine/add_medicine_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final onboardingAsync = ref.watch(onboardingDoneProvider);
  final auth = ref.watch(authControllerProvider);

  String? redirect(BuildContext context, GoRouterState state) {
    final onboardingDoneAsync = ref.watch(onboardingDoneProvider);
    final auth = ref.watch(authControllerProvider);

    final onboardingDone = onboardingDoneAsync.maybeWhen(
      data: (v) => v,
      orElse: () => null,
    );

    // Wait until onboarding value loads
    if (onboardingDone == null) return null;

    final loc = state.matchedLocation;

    // If onboarding not done -> force onboarding
    if (!onboardingDone && loc != '/onboarding') return '/onboarding';

    // If onboarding done and user not logged in -> force signin
    if (onboardingDone && !auth.isLoggedIn && loc != '/signin' && loc != '/signup') {
      return '/signin';
    }

    // If logged in -> prevent going back to auth/onboarding
    if (auth.isLoggedIn && (loc == '/signin' || loc == '/signup' || loc == '/onboarding')) {
      return '/';
    }

    return null;
  }

  return GoRouter(
    initialLocation: '/onboarding',
    redirect: redirect,
    routes: [
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/signin', builder: (_, __) => const SignInScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignUpScreen()),
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/add', builder: (_, __) => const AddMedicineScreen()),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(path: '/permissions', builder: (_, __) => const PermissionsScreen()),


    ],
  );
});
