abstract final class AppRoutes {
  AppRoutes._();

  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String recover = '/recover';
  static const String changePassword = '/change-password';

  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String activityLog = '/activity';
  static const String settings = '/settings';

  static const String createWedding = '/weddings/new';
  static const String wedding = '/weddings/:id';
  static const String editWedding = '/weddings/:id/edit';
  static const String guestDetail = '/weddings/:id/guests/:gid';
  static const String editGuest = '/weddings/:id/guests/:gid/edit';
  static const String activity = '/weddings/:id/activity';
  static const String stats = '/weddings/:id/stats';
  static const String share = '/weddings/:id/share';
  static const String invitePreview = '/invite/:token';
  static const String notifications = '/notifications';
  static const String pendingInvites = '/invites';

  static const Set<String> publicPaths = {
    onboarding,
    login,
    signup,
    recover,
    invitePreview
  };
}
