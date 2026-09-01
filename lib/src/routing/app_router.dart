import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../ui/auth/login_screen.dart';
import '../ui/auth/signup_screen.dart';
import '../ui/auth/recover_screen.dart';
import '../ui/auth/providers/session_provider.dart';
import '../ui/home/home_page.dart';
import '../ui/onboarding/onboarding_page.dart';
import '../data/models/wedding_model.dart';
import '../ui/weddings/create_wedding_screen.dart';
import '../ui/weddings/guest_list_screen.dart';
import 'app_routes.dart';
import 'global_navigator.dart';

/// App router. A single session-aware [GoRouter.redirect] guards every route:
/// unauthenticated users are confined to [AppRoutes.publicPaths]; authenticated
/// users are bounced off auth screens. `refreshListenable` re-runs the guard
/// whenever [sessionProvider] changes (login, logout, refresh-expiry).
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.home,
  refreshListenable: sessionProvider,
  redirect: _guard,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      name: 'signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: AppRoutes.recover,
      name: 'recover',
      builder: (context, state) => const RecoverScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: AppRoutes.createWedding,
      name: 'create_wedding',
      builder: (context, state) => const CreateWeddingScreen(),
    ),
    GoRoute(
      path: AppRoutes.wedding,
      name: 'wedding',
      builder: (context, state) => GuestListScreen(
        weddingId: state.pathParameters['id'] ?? '',
        wedding: state.extra is Wedding ? state.extra as Wedding : null,
      ),
    ),
  ],
);

String? _guard(BuildContext context, GoRouterState state) {
  final status = sessionProvider.status;
  final location = state.matchedLocation;
  final isPublic = AppRoutes.publicPaths.contains(location);

  // Still bootstrapping — keep the splash/initial route; don't redirect yet.
  if (status == SessionStatus.unknown) return null;

  if (status == SessionStatus.unauthenticated) {
    return isPublic ? null : AppRoutes.onboarding;
  }

  // Authenticated: keep users out of the auth flow.
  return isPublic ? AppRoutes.home : null;
}
