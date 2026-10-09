import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:zawaj_app/src/data/models/guest_detail_model.dart';
import 'package:zawaj_app/src/data/models/guest_model.dart';
import 'package:zawaj_app/src/data/repositories/guest_repository.dart';
import 'package:zawaj_app/src/shared/widgets/app_error_widget.dart';
import 'package:zawaj_app/src/theme/theme.dart';
import 'package:zawaj_app/src/ui/weddings/guest_detail_screen.dart';
import 'package:zawaj_app/src/utils/failure.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

class _MockGuestRepo implements GuestRepository {
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
  }) async =>
      throw UnimplementedError();

  _MockGuestRepo({this.result});
  final Either<Failure, GuestDetail>? result;

  @override
  FutureEither<GuestDetail> get(String weddingId, String guestId) async {
    return result ?? const Left(ServerFailure('Server error occurred'));
  }

  @override
  FutureEither<Guest> setStatus(
          String weddingId, String guestId, String status) async =>
      throw UnimplementedError();

  @override
  FutureEither<GuestNote> addNote(
          String weddingId, String guestId, String body) async =>
      throw UnimplementedError();

  @override
  FutureEither<GuestListResult> list(String weddingId,
          {String? status, String? query}) async =>
      throw UnimplementedError();

  @override
  FutureEitherVoid delete(String weddingId, String guestId) async =>
      const Right(null);

  @override
  FutureEither<Guest> create(
    String weddingId, {
    required String fullName,
    String? contact,
    String? relationship,
    String? status,
    int? companions,
    String? tableLabel,
    String? meal,
    String? note,
  }) async =>
      throw UnimplementedError();
}

Widget _buildScreen({
  Guest? initial,
  required GuestRepository repository,
  bool canEdit = false,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => GuestDetailScreen(
          weddingId: 'w1',
          guestId: 'g1',
          initial: initial,
          canEdit: canEdit,
          repository: repository,
        ),
      ),
    ],
  );

  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    builder: (context, child) => MaterialApp.router(
      theme: buildLightTheme(primaryColorHex: '#E91E63'),
      routerConfig: router,
    ),
  );
}

void main() {
  group('GuestDetailScreen widget tests', () {
    testWidgets('shows full-screen error when load fails and guest is null',
        (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo =
          _MockGuestRepo(result: const Left(ServerFailure('Server error')));

      await tester.pumpWidget(_buildScreen(repository: repo));
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorWidget), findsOneWidget);
    });

    testWidgets(
        'shows inline error banner and guest identity when load fails with initial guest',
        (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const initialGuest = Guest(
          id: 'g1', fullName: 'Amina Al-Mansoor', status: RsvpStatus.confirmed);
      final repo =
          _MockGuestRepo(result: const Left(ServerFailure('Server error')));

      await tester
          .pumpWidget(_buildScreen(initial: initialGuest, repository: repo));
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorWidget), findsOneWidget);
      expect(find.text('Amina Al-Mansoor'), findsOneWidget);
    });

    testWidgets('tapping a phone contact opens Call / WhatsApp / Copy actions',
        (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const guest = Guest(
          id: 'g1',
          fullName: 'Amina',
          contact: '0672859965',
          status: RsvpStatus.pending);
      final repo =
          _MockGuestRepo(result: const Right(GuestDetail(guest: guest)));

      await tester.pumpWidget(_buildScreen(initial: guest, repository: repo));
      await tester.pumpAndSettle();

      // Shown grouped for readability.
      expect(find.text('0672 85 99 65'), findsOneWidget);
      await tester.tap(find.text('0672 85 99 65'));
      await tester.pumpAndSettle();

      expect(find.text('guests.contact_call'), findsOneWidget);
      expect(find.text('guests.contact_whatsapp'), findsOneWidget);
      expect(find.text('guests.contact_copy'), findsOneWidget);
    });

    testWidgets('a non-phone contact is plain text with no actions',
        (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const guest = Guest(
          id: 'g1',
          fullName: 'Amina',
          contact: 'ali@x.dz',
          status: RsvpStatus.pending);
      final repo =
          _MockGuestRepo(result: const Right(GuestDetail(guest: guest)));

      await tester.pumpWidget(_buildScreen(initial: guest, repository: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ali@x.dz'));
      await tester.pumpAndSettle();
      expect(find.text('guests.contact_call'), findsNothing);
    });

    testWidgets('editors get the full Edit action, viewers do not',
        (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const guest =
          Guest(id: 'g1', fullName: 'Amina', status: RsvpStatus.pending);
      final repo =
          _MockGuestRepo(result: const Right(GuestDetail(guest: guest)));

      await tester.pumpWidget(
          _buildScreen(initial: guest, repository: repo, canEdit: true));
      await tester.pumpAndSettle();
      expect(find.byTooltip('guests.edit_action'), findsOneWidget);

      await tester.pumpWidget(_buildScreen(initial: guest, repository: repo));
      await tester.pumpAndSettle();
      expect(find.byTooltip('guests.edit_action'), findsNothing);
    });
  });
}
