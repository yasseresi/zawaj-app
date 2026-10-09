import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zawaj_app/src/data/models/user_model.dart';
import 'package:zawaj_app/src/data/repositories/auth_repository.dart';
import 'package:zawaj_app/src/shared/providers/theme_provider.dart';
import 'package:zawaj_app/src/theme/theme.dart';
import 'package:zawaj_app/src/ui/auth/providers/session_provider.dart';
import 'package:zawaj_app/src/ui/settings/settings_screen.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

class _UnusedAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();

  @override
  FutureEither<AppUser> me() async => throw UnimplementedError();
}

Future<void> _pump(WidgetTester tester, AppUser user) async {
  tester.view.physicalSize = const Size(1125, 2436);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final session = SessionProvider(repository: _UnusedAuthRepository())
    ..setAuthenticated(user);
  await tester.runAsync(() => tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('ar'), Locale('en'), Locale('fr')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider.value(value: session),
            ],
            child: Builder(
              builder: (context) => ScreenUtilInit(
                designSize: const Size(375, 812),
                builder: (context, child) => MaterialApp.router(
                  theme: buildLightTheme(primaryColorHex: '#E91E63'),
                  localizationsDelegates: context.localizationDelegates,
                  supportedLocales: context.supportedLocales,
                  locale: context.locale,
                  routerConfig: GoRouter(routes: [
                    GoRoute(
                        path: '/', builder: (_, __) => const SettingsScreen()),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ));
  await tester.pumpAndSettle();
}

Switch _switchFor(WidgetTester tester, String label) {
  final row = find.ancestor(of: find.text(label), matching: find.byType(Row));
  return tester.widget<Switch>(
      find.descendant(of: row.first, matching: find.byType(Switch)));
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('shows push and RSVP switches reflecting the user preferences',
      (tester) async {
    await _pump(
        tester,
        const AppUser(
            id: 'u1', username: 's', displayName: 'S', notifRsvp: false));

    expect(_switchFor(tester, 'Push notifications').value, isTrue);
    expect(_switchFor(tester, 'RSVP updates').value, isFalse);
    expect(_switchFor(tester, 'RSVP updates').onChanged, isNotNull);
  });

  testWidgets('RSVP switch is disabled while push is off', (tester) async {
    await _pump(
        tester,
        const AppUser(
            id: 'u1', username: 's', displayName: 'S', notifPush: false));

    expect(_switchFor(tester, 'RSVP updates').onChanged, isNull);
  });

  testWidgets('shows the formatted phone on the profile card', (tester) async {
    await _pump(
        tester,
        const AppUser(
            id: 'u1', username: 's', displayName: 'S', phone: '0672859965'));

    expect(find.text('0672 85 99 65'), findsOneWidget);
  });
}
