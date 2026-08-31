import 'package:zawaj_app/src/imports/core_imports.dart';
import 'package:zawaj_app/src/imports/packages_imports.dart';

import 'package:zawaj_app/src/ui/auth/providers/session_provider.dart';

/// Removes the native splash once the session status is resolved.
///
/// Navigation is intentionally NOT done here — the router's session-aware
/// redirect (`appRouter`) is the single source of truth for where the user
/// lands. This wrapper only lifts the splash so the first real frame shows.
class SessionListenerWrapper extends StatefulWidget {
  final Widget child;
  const SessionListenerWrapper({super.key, required this.child});

  @override
  State<SessionListenerWrapper> createState() => _SessionListenerWrapperState();
}

class _SessionListenerWrapperState extends State<SessionListenerWrapper> {
  bool _splashRemoved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = Provider.of<SessionProvider>(context);
    if (!_splashRemoved && session.status != SessionStatus.unknown) {
      _splashRemoved = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FlutterNativeSplash.remove();
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
