import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zawaj_app/src/data/models/guest_model.dart';
import 'package:zawaj_app/src/data/models/wedding_model.dart';
import 'package:zawaj_app/src/data/repositories/guest_repository.dart';
import 'package:zawaj_app/src/data/repositories/wedding_repository.dart';
import 'package:zawaj_app/src/theme/theme.dart';
import 'package:zawaj_app/src/ui/weddings/guest_list_screen.dart';
import 'package:zawaj_app/src/utils/failure.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

class _FakeWeddingRepository implements WeddingRepository {
  _FakeWeddingRepository(this.getResult);
  final Either<Failure, Wedding> getResult;

  @override
  FutureEither<Wedding> get(String id) async => getResult;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _EmptyGuestRepository implements GuestRepository {
  @override
  FutureEither<GuestListResult> list(String weddingId,
          {String? status, String? query}) async =>
      const Right(GuestListResult(items: []));

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<void> _pump(WidgetTester tester, WeddingRepository repo,
    {Wedding? initial}) async {
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => GuestListScreen(
        weddingId: 'w1',
        wedding: initial,
        weddingRepository: repo,
        guestRepository: _EmptyGuestRepository(),
      ),
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
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('cold-loads the wedding when opened without navigation extra',
      (tester) async {
    await _pump(
        tester,
        _FakeWeddingRepository(const Right(Wedding(
            id: 'w1',
            name: 'Leila & Omar',
            ownerId: 'u1',
            role: WeddingRole.editor))));

    expect(find.text('Leila & Omar'), findsOneWidget);
    // Editors can add guests.
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets(
      'shows a not-found state when the wedding is gone or inaccessible',
      (tester) async {
    await _pump(
        tester, _FakeWeddingRepository(const Left(NotFoundFailure('nope'))),
        initial: const Wedding(
            id: 'w1',
            name: 'Leila & Omar',
            ownerId: 'u1',
            role: WeddingRole.owner));

    expect(find.text('Wedding not available'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('adopts the fresh role: a demoted viewer loses the add button',
      (tester) async {
    await _pump(
        tester,
        _FakeWeddingRepository(const Right(Wedding(
            id: 'w1',
            name: 'Leila & Omar',
            ownerId: 'u1',
            role: WeddingRole.viewer))),
        initial: const Wedding(
            id: 'w1',
            name: 'Leila & Omar',
            ownerId: 'u1',
            role: WeddingRole.editor));

    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('only the owner gets the edit action', (tester) async {
    const owned = Wedding(
        id: 'w1', name: 'Leila & Omar', ownerId: 'u1', role: WeddingRole.owner);
    await _pump(tester, _FakeWeddingRepository(const Right(owned)),
        initial: owned);
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    expect(find.text('Edit details'), findsOneWidget);
  });

  testWidgets('editors do not get the owner menu', (tester) async {
    const shared = Wedding(
        id: 'w1',
        name: 'Leila & Omar',
        ownerId: 'u1',
        role: WeddingRole.editor);
    await _pump(tester, _FakeWeddingRepository(const Right(shared)),
        initial: shared);

    expect(find.byTooltip('More actions'), findsNothing);
  });
}
