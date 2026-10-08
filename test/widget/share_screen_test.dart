import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zawaj_app/src/data/models/invite_link_model.dart';
import 'package:zawaj_app/src/data/models/join_request_model.dart';
import 'package:zawaj_app/src/data/models/wedding_member_model.dart';
import 'package:zawaj_app/src/data/models/wedding_model.dart';
import 'package:zawaj_app/src/data/repositories/invite_repository.dart';
import 'package:zawaj_app/src/data/repositories/wedding_repository.dart';
import 'package:zawaj_app/src/theme/theme.dart';
import 'package:zawaj_app/src/ui/share/share_screen.dart';
import 'package:zawaj_app/src/ui/share/widgets/role_picker_sheet.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

const _owner = WeddingMember(
    userId: 'u1',
    username: 'sarah',
    displayName: 'Sarah',
    role: WeddingRole.owner);
const _editorReq = JoinRequest(
    id: 'r1',
    userId: 'u3',
    username: 'lina',
    displayName: 'Lina',
    role: WeddingRole.editor);
const _viewerReq = JoinRequest(
    id: 'r2',
    userId: 'u4',
    username: 'omar',
    displayName: 'Omar',
    role: WeddingRole.viewer);

class _Weddings implements WeddingRepository {
  _Weddings(this.requests);
  final List<JoinRequest> requests;
  final approvals = <(String, WeddingRole?)>[];
  final declines = <String>[];

  @override
  FutureEither<List<WeddingMember>> members(String id) async =>
      const Right([_owner]);
  @override
  FutureEither<List<InviteLink>> listInviteLinks(String id) async =>
      const Right([]);
  @override
  FutureEither<List<JoinRequest>> listJoinRequests(String weddingId) async =>
      Right(requests);
  @override
  FutureEither<void> approveJoinRequest(String weddingId, String requestId,
      {WeddingRole? role}) async {
    approvals.add((requestId, role));
    return const Right(null);
  }

  @override
  FutureEither<void> declineJoinRequest(
      String weddingId, String requestId) async {
    declines.add(requestId);
    return const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _NoInvites implements InviteRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Finder _inSheet(String text) => find.descendant(
    of: find.byType(RolePickerSheet), matching: find.text(text));

Future<_Weddings> _pump(WidgetTester tester, List<JoinRequest> requests,
    {WeddingRole role = WeddingRole.owner}) async {
  final repo = _Weddings(requests);
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
              routerConfig: GoRouter(routes: [
                GoRoute(
                  path: '/',
                  builder: (_, __) => ShareScreen(
                    weddingId: 'w1',
                    wedding: Wedding(
                        id: 'w1', name: 'L&O', ownerId: 'u1', role: role),
                    weddingRepository: repo,
                    inviteRepository: _NoInvites(),
                  ),
                ),
              ]),
            ),
          ),
        ),
      )));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('owners see pending join requests', (tester) async {
    await _pump(tester, const [_editorReq, _viewerReq]);
    expect(find.text('Join requests (2)'), findsOneWidget);
    expect(find.text('Lina'), findsOneWidget);
    expect(find.text('Omar'), findsOneWidget);
  });

  testWidgets('an editor request can be approved as editor from the sheet',
      (tester) async {
    final repo = await _pump(tester, const [_editorReq]);

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    expect(_inSheet('Can edit'), findsOneWidget);
    expect(_inSheet('View only'), findsOneWidget);

    await tester.tap(_inSheet('Can edit')); // the preselected role
    await tester.pumpAndSettle();
    expect(repo.approvals, [('r1', null)]); // requested role: no override sent
    expect(find.text('Join requests (1)'), findsNothing); // row left the list
    expect(find.text('Lina'), findsNothing);
  });

  testWidgets('approving at a lower role sends it', (tester) async {
    final repo = await _pump(tester, const [_editorReq]);
    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    await tester.tap(_inSheet('View only'));
    await tester.pumpAndSettle();
    expect(repo.approvals, [('r1', WeddingRole.viewer)]);
  });

  testWidgets('a viewer request is approved without a role sheet',
      (tester) async {
    final repo = await _pump(tester, const [_viewerReq]);
    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    expect(find.byType(RolePickerSheet), findsNothing);
    expect(repo.approvals, [('r2', null)]);
  });

  testWidgets('decline asks first; cancelling sends nothing', (tester) async {
    final repo = await _pump(tester, const [_editorReq]);

    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    expect(find.text('Decline Lina?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo.declines, isEmpty);

    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decline').last); // the dialog's confirm
    await tester.pumpAndSettle();
    expect(repo.declines, ['r1']);
    expect(find.text('Lina'), findsNothing);
  });
}
