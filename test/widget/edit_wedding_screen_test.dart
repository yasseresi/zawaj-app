import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:zawaj_app/src/data/models/wedding_model.dart';
import 'package:zawaj_app/src/data/repositories/wedding_repository.dart';
import 'package:zawaj_app/src/shared/widgets/app_button.dart';
import 'package:zawaj_app/src/theme/theme.dart';
import 'package:zawaj_app/src/ui/weddings/edit_wedding_screen.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

class _FakeWeddingRepository implements WeddingRepository {
  int updates = 0;

  @override
  FutureEither<Wedding> update(String id,
      {String? name, String? eventDate, String? description}) async {
    updates++;
    return Right(_wedding.copyWith(name: name));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const _wedding = Wedding(
    id: 'w1', name: 'Leila & Omar', ownerId: 'u1', role: WeddingRole.owner);

Future<_FakeWeddingRepository> _pump(WidgetTester tester) async {
  final repo = _FakeWeddingRepository();
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (context, _) => Scaffold(
        body: TextButton(
          onPressed: () => context.push('/edit'),
          child: const Text('open'),
        ),
      ),
    ),
    GoRoute(
      path: '/edit',
      builder: (_, __) =>
          EditWeddingScreen(wedding: _wedding, repository: repo),
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
  return repo;
}

AppButton _save(WidgetTester tester) =>
    tester.widget<AppButton>(find.byType(AppButton));

void main() {
  testWidgets('prefills the wedding and enables Save only after a change',
      (tester) async {
    await _pump(tester);

    expect(find.text('Leila & Omar'), findsOneWidget);
    expect(_save(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextFormField).first, 'L & O');
    await tester.pump();
    expect(_save(tester).onPressed, isNotNull);

    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.pump();
    expect(_save(tester).onPressed, isNull);
  });

  testWidgets('leaving with unsaved edits asks to discard', (tester) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextFormField).first, 'L & O');
    await tester.pump();

    final popped = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(popped, isTrue);
    expect(find.text('actions.discard_title'), findsOneWidget);

    await tester.tap(find.text('actions.keep_editing'));
    await tester.pumpAndSettle();
    expect(find.byType(EditWeddingScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('actions.discard'));
    await tester.pumpAndSettle();
    expect(find.byType(EditWeddingScreen), findsNothing);
  });

  testWidgets('leaving without changes does not ask', (tester) async {
    await _pump(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('actions.discard_title'), findsNothing);
    expect(find.byType(EditWeddingScreen), findsNothing);
  });

  testWidgets('Save sends the change and closes', (tester) async {
    final repo = await _pump(tester);
    await tester.enterText(find.byType(TextFormField).first, 'L & O');
    await tester.pump();

    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    expect(repo.updates, 1);
    expect(find.byType(EditWeddingScreen), findsNothing);
  });
}
