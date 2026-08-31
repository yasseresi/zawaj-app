import '../../imports/imports.dart';
import '../../ui/auth/providers/auth_provider.dart';
import '../../ui/auth/providers/session_provider.dart';
import '../providers/theme_provider.dart';

/// Registers the app-wide providers.
///
/// - [SessionProvider]: the single global instance (also used by the router as
///   `refreshListenable`) — provided via `.value` so it isn't recreated.
/// - [ThemeProvider]: theme mode (loads its persisted value eagerly).
/// - [AuthProvider]: auth form state, bound to the global session.
class StateWrapper extends StatelessWidget {
  final Widget child;

  const StateWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionProvider>.value(value: sessionProvider),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()..load()),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(session: sessionProvider),
        ),
      ],
      child: child,
    );
  }
}
