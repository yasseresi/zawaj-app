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
  _MockGuestRepo({this.result});
  final Either<Failure, GuestDetail>? result;

  @override
  FutureEither<GuestDetail> get(String weddingId, String guestId) async {
    return result ?? const Left(ServerFailure('Server error occurred'));
  }

  @override
  FutureEither<Guest> setStatus(String weddingId, String guestId, String status) async =>
      throw UnimplementedError();

  @override
  FutureEither<GuestNote> addNote(String weddingId, String guestId, String body) async =>
      throw UnimplementedError();

  @override
  FutureEither<GuestListResult> list(String weddingId, {String? status, String? query}) async =>
      throw UnimplementedError();

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
    testWidgets('shows full-screen error when load fails and guest is null', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _MockGuestRepo(result: const Left(ServerFailure('Server error')));

      await tester.pumpWidget(_buildScreen(repository: repo));
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorWidget), findsOneWidget);
    });

    testWidgets('shows inline error banner and guest identity when load fails with initial guest', (tester) async {
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const initialGuest = Guest(id: 'g1', fullName: 'Amina Al-Mansoor', status: RsvpStatus.confirmed);
      final repo = _MockGuestRepo(result: const Left(ServerFailure('Server error')));

      await tester.pumpWidget(_buildScreen(initial: initialGuest, repository: repo));
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorWidget), findsOneWidget);
      expect(find.text('Amina Al-Mansoor'), findsOneWidget);
    });
  });
}
