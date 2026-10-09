import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zawaj_app/src/data/models/user_model.dart';
import 'package:zawaj_app/src/data/models/wedding_member_model.dart';
import 'package:zawaj_app/src/data/models/wedding_model.dart';
import 'package:zawaj_app/src/data/repositories/auth_repository.dart';
import 'package:zawaj_app/src/data/repositories/wedding_repository.dart';
import 'package:zawaj_app/src/shared/widgets/app_button.dart';
import 'package:zawaj_app/src/theme/theme.dart';
import 'package:zawaj_app/src/ui/auth/providers/session_provider.dart';
import 'package:zawaj_app/src/ui/settings/delete_account_screen.dart';
import 'package:zawaj_app/src/utils/failure.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

class _FakeWeddingRepository implements WeddingRepository {
  @override
  FutureEither<List<Wedding>> myWeddings() async => const Right([
        Wedding(
            id: 'w1',
            name: 'Leila & Omar',
            ownerId: 'u1',
            role: WeddingRole.owner,
            guestCount: 80),
      ]);

  @override
  FutureEither<List<WeddingMember>> members(String id) async => const Right([
        WeddingMember(
            userId: 'u1',
            username: 's',
            displayName: 'S',
            role: WeddingRole.owner),
        WeddingMember(
            userId: 'u2',
            username: 'o',
            displayName: 'O',
            role: WeddingRole.editor),
      ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeAuthRepository implements AuthRepository {
  Either<Failure, void> deleteResult =
      const Left(AuthFailure('password is incorrect'));

  @override
  FutureEitherVoid deleteAccount({required String password}) async =>
      deleteResult;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<SessionProvider> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1125, 2436);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final session = SessionProvider(repository: _FakeAuthRepository())
    ..setAuthenticated(
        const AppUser(id: 'u1', username: 's', displayName: 'S'));
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => DeleteAccountScreen(
          weddingRepository: _FakeWeddingRepository(), session: session),
    ),
  ]);
  await tester.runAsync(() => tester.pumpWidget(EasyLocalization(
        supportedLocales: const [Locale('ar'), Locale('en'), Locale('fr')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        child: Builder(
          builder: (context) => ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (context, child) => MaterialApp.router(
              theme: buildLightTheme(primaryColorHex: '#E91E63'),
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              routerConfig: router,
            ),
          ),
        ),
      )));
  await tester.pumpAndSettle();
  return session;
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('step 1 lists owned weddings with a transfer shortcut',
      (tester) async {
    await _pump(tester);

    expect(find.text('Leila & Omar'), findsOneWidget);
    expect(find.textContaining('1 collaborator'), findsOneWidget);
    expect(find.text('Transfer ownership'), findsOneWidget);
  });

  testWidgets('step 2 gates the delete button on a password', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    final button = find.widgetWithText(AppButton, 'Delete permanently');
    expect(tester.widget<AppButton>(button).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'secret');
    await tester.pump();
    expect(tester.widget<AppButton>(button).onPressed, isNotNull);
  });

  testWidgets('a wrong password shows an inline error and keeps the session',
      (tester) async {
    final session = await _pump(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'wrong');
    await tester.pump();

    await tester.tap(find.text('Delete permanently'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect password'), findsOneWidget);
    expect(session.isAuthenticated, isTrue);
  });
}
