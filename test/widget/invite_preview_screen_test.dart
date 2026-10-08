import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zawaj_app/src/data/models/invite_link_model.dart';
import 'package:zawaj_app/src/data/models/join_request_model.dart';
import 'package:zawaj_app/src/data/models/user_model.dart';
import 'package:zawaj_app/src/data/models/wedding_model.dart';
import 'package:zawaj_app/src/data/repositories/auth_repository.dart';
import 'package:zawaj_app/src/data/repositories/wedding_repository.dart';
import 'package:zawaj_app/src/theme/theme.dart';
import 'package:zawaj_app/src/ui/auth/providers/session_provider.dart';
import 'package:zawaj_app/src/ui/share/invite_preview_screen.dart';
import 'package:zawaj_app/src/utils/failure.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

class _Weddings implements WeddingRepository {
  _Weddings(this.acceptResult, {this.gate});
  final Either<Failure, JoinResult> acceptResult;
  final Completer<void>? gate;

  @override
  FutureEither<InvitePreview> previewInvite(String token) async =>
      const Right(InvitePreview(
          weddingId: 'w1', weddingName: 'Leila & Karim', role: 'editor'));

  @override
  FutureEither<JoinResult> acceptInviteLink(String token) async {
    await gate?.future;
    return acceptResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _NoAuth implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<void> _pump(WidgetTester tester, Either<Failure, JoinResult> accept,
    {Completer<void>? gate}) async {
  final session = SessionProvider(repository: _NoAuth())
    ..setAuthenticated(
        const AppUser(id: 'u2', username: 'omar', displayName: 'Omar'));
  final router = GoRouter(initialLocation: '/i/TOK', routes: [
    GoRoute(path: '/', builder: (_, __) => const Text('home page')),
    GoRoute(
      path: '/i/:token',
      builder: (_, __) => InvitePreviewScreen(
          token: 'MFRGGZDFMZTWQ2LKNNWG23TP',
          weddingRepository: _Weddings(accept, gate: gate)),
    ),
    GoRoute(
        path: '/weddings/:id', builder: (_, __) => const Text('wedding page')),
  ]);
  await tester.runAsync(() => tester.pumpWidget(EasyLocalization(
        supportedLocales: const [Locale('ar'), Locale('en'), Locale('fr')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        child: Builder(
          builder: (context) => ChangeNotifierProvider<SessionProvider>.value(
            value: session,
            child: ScreenUtilInit(
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
        ),
      )));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('a pending request shows "Request sent" and stays put',
      (tester) async {
    await _pump(
        tester,
        const Right(JoinResult(
            weddingId: 'w1',
            weddingName: 'Leila & Karim',
            role: WeddingRole.editor,
            isPending: true,
            requestId: 'r1')));

    expect(find.text('Request to join'), findsOneWidget);
    await tester.tap(find.text('Request to join'));
    await tester.pumpAndSettle();

    expect(find.text('Request sent'), findsOneWidget);
    expect(find.textContaining('Leila & Karim'), findsOneWidget);
    expect(find.text('wedding page'), findsNothing);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('home page'), findsOneWidget);
  });

  testWidgets('an existing member is taken to the wedding', (tester) async {
    await _pump(
        tester,
        const Right(JoinResult(
            weddingId: 'w1',
            weddingName: 'Leila & Karim',
            role: WeddingRole.viewer,
            isPending: false)));

    await tester.tap(find.text('Request to join'));
    await tester.pumpAndSettle();
    expect(find.text('wedding page'), findsOneWidget);
  });

  testWidgets('a refusal keeps the card and shows why', (tester) async {
    await _pump(tester,
        const Left(ForbiddenFailure('removed', code: 'removed_from_wedding')));

    await tester.tap(find.text('Request to join'));
    await tester.pumpAndSettle();

    expect(find.text('Leila & Karim'), findsOneWidget);
    expect(find.textContaining('removed you'), findsOneWidget);
  });

  testWidgets('says the owner will review, and shows progress while sending',
      (tester) async {
    final gate = Completer<void>();
    await _pump(
        tester,
        const Right(JoinResult(
            weddingId: 'w1',
            weddingName: 'Leila & Karim',
            role: WeddingRole.editor,
            isPending: true,
            requestId: 'r1')),
        gate: gate);

    expect(find.textContaining("You'll ask to join as"), findsOneWidget);
    await tester.tap(find.text('Request to join'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Request sent'), findsOneWidget);
  });

  testWidgets('a full request queue is explained on the card', (tester) async {
    await _pump(
        tester, const Left(ServerFailure('too many', code: 'join_queue_full')));
    await tester.tap(find.text('Request to join'));
    await tester.pumpAndSettle();
    expect(find.textContaining('too many pending requests'), findsOneWidget);
  });
}
