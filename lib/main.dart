import 'src/imports/core_imports.dart';
import 'src/imports/packages_imports.dart';
import 'src/app.dart';
import 'src/ui/auth/providers/session_provider.dart';
import 'src/routing/invite_deep_link.dart';
import 'package:app_links/app_links.dart';

void _openInvite(Uri uri) {
  final token = parseInviteToken(uri);
  if (token != null && token.isNotEmpty) {
    pendingInviteToken = token;
    appRouter.go(AppRoutes.invitePreview.replaceFirst(':token', token));
  }
}

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await EasyLocalization.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Order matters: prefs (theme) → HTTP client (interceptors) → session bootstrap
  // (reads persisted tokens and resolves the initial auth state before first frame).
  await StorageService.instance.init();
  await AppConfig.init();
  await sessionProvider.bootstrap();

  runApp(
    EasyLocalization(
      startLocale: const Locale('ar'), // Arabic-first (RTL) by default
      supportedLocales: const [Locale('ar'), Locale('en'), Locale('fr')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      child: const StateWrapper(
        child: App(),
      ),
    ),
  );

  final links = AppLinks();
  final initial = await links.getInitialLink();
  if (initial != null) _openInvite(initial);
  links.uriLinkStream.listen(_openInvite);
}
