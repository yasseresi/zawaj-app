/// Centralized route path + name constants for GoRouter.
///
/// Use these instead of raw strings: `context.goNamed(AppRoutes.home)`.
abstract final class AppRoutes {
  AppRoutes._();

  // Auth flow
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String recover = '/recover';

  // App
  static const String home = '/';
  static const String createWedding = '/weddings/new';
  static const String wedding = '/weddings/:id'; // guests list for a wedding
  static const String guestDetail = '/weddings/:id/guests/:gid';
  static const String activity = '/weddings/:id/activity';
  static const String stats = '/weddings/:id/stats';
  static const String share = '/weddings/:id/share';
  static const String invitePreview = '/invite/:token';
  static const String notifications = '/notifications';
  static const String pendingInvites = '/invites';
  static const String settings = '/settings';

  /// Routes reachable while unauthenticated (the guard allows only these).
  static const Set<String> publicPaths = {onboarding, login, signup, recover};
}
