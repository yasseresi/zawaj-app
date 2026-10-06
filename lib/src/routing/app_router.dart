import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/guest_model.dart';
import '../data/models/wedding_model.dart';
import '../ui/activity/activity_log_screen.dart';
import '../ui/analytics/analytics_screen.dart';
import '../ui/auth/login_screen.dart';
import '../ui/auth/providers/session_provider.dart';
import '../ui/auth/recover_screen.dart';
import '../ui/auth/signup_screen.dart';
import '../ui/home/home_page.dart';
import '../ui/invites/pending_invites_screen.dart';
import '../ui/notifications/notifications_screen.dart';
import '../ui/onboarding/onboarding_page.dart';
import '../ui/settings/settings_screen.dart';
import '../ui/settings/change_password_screen.dart';
import '../ui/settings/providers/settings_provider.dart';
import '../ui/share/share_screen.dart';
import '../ui/share/invite_preview_screen.dart';
import '../ui/shell/main_navigation_shell.dart';
import '../ui/weddings/create_wedding_screen.dart';
import '../ui/weddings/edit_guest_screen.dart';
import '../ui/weddings/edit_wedding_screen.dart';
import '../ui/weddings/guest_detail_screen.dart';
import '../ui/weddings/guest_list_screen.dart';
import '../services/storage_service.dart';
import 'app_routes.dart';
import 'global_navigator.dart';

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
      path: AppRoutes.changePassword,
      name: 'change_password',
      builder: (context, state) => ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(),
        child: const ChangePasswordScreen(),
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => MainNavigationShell(
        navigationShell: navigationShell,
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              name: 'home',
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              name: 'dashboard',
              builder: (context, state) => const DashboardTabPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.activityLog,
              name: 'activity_log',
              builder: (context, state) => const ActivityTabPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              name: 'settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
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
    GoRoute(
      path: AppRoutes.editWedding,
      name: 'edit_wedding',
      // Needs the wedding (with the caller's role) from the wedding screen;
      // a cold deep link goes to the wedding itself instead.
      redirect: (context, state) => state.extra is Wedding
          ? null
          : '/weddings/${state.pathParameters['id']}',
      builder: (context, state) =>
          EditWeddingScreen(wedding: state.extra! as Wedding),
    ),
    GoRoute(
      path: AppRoutes.guestDetail,
      name: 'guest_detail',
      builder: (context, state) {
        final args = state.extra is GuestDetailArgs
            ? state.extra as GuestDetailArgs
            : const GuestDetailArgs();
        return GuestDetailScreen(
          weddingId: state.pathParameters['id'] ?? '',
          guestId: state.pathParameters['gid'] ?? '',
          initial: args.initial,
          canEdit: args.canEdit,
          onGuestUpdated: args.onGuestUpdated,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.editGuest,
      name: 'edit_guest',
      // Needs the guest from the detail screen; a cold deep link goes there.
      redirect: (context, state) => state.extra is Guest
          ? null
          : '/weddings/${state.pathParameters['id']}/guests/${state.pathParameters['gid']}',
      builder: (context, state) => EditGuestScreen(
        weddingId: state.pathParameters['id'] ?? '',
        guest: state.extra! as Guest,
      ),
    ),
    GoRoute(
      path: AppRoutes.activity,
      name: 'activity',
      builder: (context, state) => ActivityLogScreen(
        weddingId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: AppRoutes.stats,
      name: 'stats',
      builder: (context, state) => AnalyticsScreen(
        weddingId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: AppRoutes.pendingInvites,
      name: 'pending_invites',
      builder: (context, state) => const PendingInvitesScreen(),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      name: 'notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
        path: AppRoutes.share,
        name: 'share',
        builder: (context, state) => ShareScreen(
            weddingId: state.pathParameters['id'] ?? '',
            wedding: state.extra is Wedding ? state.extra as Wedding : null)),
    GoRoute(
        path: AppRoutes.invitePreview,
        name: 'invite_preview',
        builder: (context, state) =>
            InvitePreviewScreen(token: state.pathParameters['token'] ?? '')),
  ],
);

String? pendingInviteToken;

String? _guard(BuildContext context, GoRouterState state) {
  final status = sessionProvider.status;
  final location = state.matchedLocation;
  final isInvitePreview = location.startsWith('/invite/');
  final isPublic = AppRoutes.publicPaths.contains(location) || isInvitePreview;

  if (status == SessionStatus.unknown) return null;

  if (status == SessionStatus.unauthenticated) {
    final onboardingCompleted = StorageService.instance.hasCompletedOnboarding;
    if (location == AppRoutes.onboarding) {
      return onboardingCompleted ? AppRoutes.login : null;
    }
    if (!onboardingCompleted) {
      return isPublic ? null : AppRoutes.onboarding;
    }
    return isPublic ? null : AppRoutes.login;
  }

  if (pendingInviteToken != null && !isInvitePreview) {
    return '/invite/$pendingInviteToken';
  }

  return isPublic && !isInvitePreview ? AppRoutes.home : null;
}
