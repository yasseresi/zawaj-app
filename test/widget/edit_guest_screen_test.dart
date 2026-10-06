import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:zawaj_app/src/data/models/guest_model.dart';
import 'package:zawaj_app/src/data/repositories/guest_repository.dart';
import 'package:zawaj_app/src/shared/widgets/app_button.dart';
import 'package:zawaj_app/src/theme/theme.dart';
import 'package:zawaj_app/src/ui/weddings/edit_guest_screen.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

class _FakeGuestRepository implements GuestRepository {
  String? sentName;

  @override
  FutureEither<Guest> update(
    String weddingId,
    String guestId, {
    String? fullName,
    String? contact,
    String? relationship,
    String? status,
    int? companions,
    String? tableLabel,
    String? meal,
  }) async {
    sentName = fullName;
    return Right(Guest(id: guestId, fullName: fullName ?? 'Amina'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<(_FakeGuestRepository, List<Guest?>)> _pump(
    WidgetTester tester, Guest guest) async {
  tester.view.physicalSize = const Size(1125, 2436);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final repo = _FakeGuestRepository();
  final results = <Guest?>[];
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (context, _) => Scaffold(
        body: TextButton(
          onPressed: () async =>
              results.add(await context.push<Guest>('/edit')),
          child: const Text('open'),
        ),
      ),
    ),
    GoRoute(
      path: '/edit',
      builder: (_, __) =>
          EditGuestScreen(weddingId: 'w1', guest: guest, repository: repo),
    ),
  ]);
  await tester.pumpWidget(ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (context, child) => MaterialApp.router(
      theme: buildLightTheme(primaryColorHex: '#E91E63'),
      routerConfig: router,
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return (repo, results);
}

AppButton _save(WidgetTester tester) =>
    tester.widget<AppButton>(find.byType(AppButton));

void main() {
  const guest = Guest(
      id: 'g1',
      fullName: 'Amina',
      contact: '0672859965',
      relationship: 'Cousin',
      companions: 2);

  testWidgets('prefills every field, phone grouped', (tester) async {
    await _pump(tester, guest);

    expect(find.text('Amina'), findsOneWidget);
    expect(find.text('0672 85 99 65'), findsOneWidget);
    expect(find.text('Cousin'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(_save(tester).onPressed, isNull);
  });

  testWidgets('an invalid phone blocks Save', (tester) async {
    await _pump(tester, guest);

    await tester.enterText(find.byType(TextFormField).at(1), '0551');
    await tester.pump();

    expect(_save(tester).onPressed, isNull);
  });

  testWidgets('saving pops the updated guest', (tester) async {
    final (repo, results) = await _pump(tester, guest);

    await tester.enterText(find.byType(TextFormField).first, 'Amina B');
    await tester.pump();
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    expect(repo.sentName, 'Amina B');
    expect(results.single?.fullName, 'Amina B');
  });

  testWidgets('a legacy email contact can be kept while editing other fields',
      (tester) async {
    await _pump(
        tester, const Guest(id: 'g2', fullName: 'Ali', contact: 'ali@x.dz'));

    expect(find.text('ali@x.dz'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Ali B');
    await tester.pump();

    expect(_save(tester).onPressed, isNotNull);
  });
}
