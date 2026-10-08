import 'src/imports/core_imports.dart';
import 'src/imports/packages_imports.dart';
import 'src/app.dart';
import 'src/ui/auth/providers/session_provider.dart';
import 'src/routing/invite_deep_link.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage _) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

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

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await EasyLocalization.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Order matters: prefs (theme) → HTTP client (interceptors) → session bootstrap
  // (reads persisted tokens and resolves the initial auth state before first frame).
  await StorageService.instance.init();
  await AppConfig.init();
  await sessionProvider.bootstrap();
  await PushNotificationService.instance.initialize();

  runApp(
    EasyLocalization(
      startLocale: const Locale('ar'), // Arabic-first (RTL) by default
      supportedLocales: const [Locale('ar'), Locale('en'), Locale('fr')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      // Use each language's CLDR plural rules (Arabic few/many, etc.); the
      // default only distinguishes zero/one/two/other.
      ignorePluralRules: false,
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
