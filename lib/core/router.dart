import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../features/auth/signin_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/home/home_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/meds/meds_screen.dart';

// Add-med flow
import '../features/meds/add_flow/step1_name_screen.dart';
import '../features/meds/add_flow/step2_form_screen.dart';
import '../features/meds/add_flow/step3_frequency_screen.dart';
import '../features/meds/add_flow/step4_times_screen.dart';
import '../features/meds/add_flow/step5_review_times_screen.dart';
import '../features/meds/add_flow/step6_dose_screen.dart';
import '../features/meds/add_flow/step7_summary_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  String? redirect(BuildContext context, GoRouterState state) {
    final onboardingDoneAsync = ref.watch(onboardingDoneProvider);
    final auth = ref.watch(authControllerProvider);

    // If onboarding state still loading -> don't redirect yet
    final onboardingDone = onboardingDoneAsync.maybeWhen(
      data: (v) => v,
      orElse: () => null,
    );
    if (onboardingDone == null) return null;

    final loc = state.matchedLocation;

    final isOnboarding = loc == '/onboarding';
    final isAuth = loc == '/signin' || loc == '/signup';

    // 1) If onboarding NOT done -> force onboarding
    if (!onboardingDone && !isOnboarding) return '/onboarding';

    // 2) If onboarding done, but NOT logged in -> force signin/signup only
    if (onboardingDone && !auth.isLoggedIn && !isAuth) return '/signin';

    // 3) If logged in -> block going back to onboarding/signin/signup
    if (auth.isLoggedIn && (isOnboarding || isAuth)) return '/';

    return null;
  }

  return GoRouter(
    // ✅ IMPORTANT: start at "/" and let redirect decide
    initialLocation: '/',
    redirect: redirect,
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/signin',
        builder: (_, __) => const SignInScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, __) => const SignUpScreen(),
      ),

      // ✅ Tabs shell (Home / Meds / Settings)
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/meds',
            builder: (_, __) => const MedsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),

          // ✅ Add-med wizard routes
          GoRoute(
            path: '/meds/add/name',
            builder: (_, __) => const Step1NameScreen(),
          ),
          GoRoute(
            path: '/meds/add/form',
            builder: (_, __) => const Step2FormScreen(),
          ),
          GoRoute(
            path: '/meds/add/frequency',
            builder: (_, __) => const Step3FrequencyScreen(),
          ),
          GoRoute(
            path: '/meds/add/times',
            builder: (_, __) => const Step4TimesScreen(),
          ),
          GoRoute(
            path: '/meds/add/review',
            builder: (_, __) => const Step5ReviewTimesScreen(),
          ),
          GoRoute(
            path: '/meds/add/dose',
            builder: (_, __) => const Step6DoseScreen(),
          ),
          GoRoute(
            path: '/meds/add/summary',
            builder: (_, __) => const Step7SummaryScreen(),
          ),
        ],
      ),
    ],
  );
});
