import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zawaj_app/src/data/models/guest_detail_model.dart';
import 'package:zawaj_app/src/data/models/guest_model.dart';
import 'package:zawaj_app/src/data/repositories/guest_repository.dart';
import 'package:zawaj_app/src/shared/widgets/app_empty_state.dart';
import 'package:zawaj_app/src/theme/theme.dart';
import 'package:zawaj_app/src/ui/analytics/analytics_screen.dart';
import 'package:zawaj_app/src/ui/analytics/widgets/broadcast_sheet.dart';
import 'package:zawaj_app/src/ui/analytics/widgets/donut_chart_widget.dart';
import 'package:zawaj_app/src/ui/analytics/widgets/timeline_chart_widget.dart';
import 'package:zawaj_app/src/utils/failure.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

class _FakeGuestRepository implements GuestRepository {
  _FakeGuestRepository({this.result});
  final Either<Failure, GuestListResult>? result;

  @override
  FutureEither<GuestListResult> list(
    String weddingId, {
    String? status,
    String? query,
  }) async {
    return result ??
        const Right(
          GuestListResult(
            counts: GuestCounts(
              all: 245,
              confirmed: 142,
              declined: 24,
              pending: 79,
            ),
          ),
        );
  }

  @override
  FutureEither<GuestDetail> get(String weddingId, String guestId) async =>
      throw UnimplementedError();

  @override
  FutureEither<Guest> setStatus(
          String weddingId, String guestId, String status) async =>
      throw UnimplementedError();

  @override
  FutureEither<GuestNote> addNote(
          String weddingId, String guestId, String body) async =>
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

  @override
  FutureEither<int> sendReminders(String weddingId) async => const Right(79);
}

Widget _buildWidget({required GuestRepository repository}) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (context, _) => MaterialApp(
      theme: buildLightTheme(primaryColorHex: '#C9796A'),
      home: AnalyticsScreen(
        weddingId: 'w1',
        repository: repository,
      ),
    ),
  );
}

void main() {
  testWidgets('renders stat cards, donut chart and timeline chart on load',
      (tester) async {
    final repo = _FakeGuestRepository();

    await tester.pumpWidget(_buildWidget(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('245'), findsWidgets);
    expect(find.text('79'), findsWidgets);

    expect(find.byType(DonutChartWidget), findsOneWidget);
    expect(find.byType(TimelineChartWidget), findsOneWidget);
  });

  testWidgets('shows empty state when total guests count is 0',
      (tester) async {
    final repo = _FakeGuestRepository(
      result: const Right(GuestListResult(counts: GuestCounts())),
    );

    await tester.pumpWidget(_buildWidget(repository: repo));
    await tester.pumpAndSettle();

    expect(find.byType(AppEmptyState), findsOneWidget);
  });

  testWidgets('shows broadcast sheet when Send Reminders button is tapped',
      (tester) async {
    final repo = _FakeGuestRepository();

    await tester.pumpWidget(_buildWidget(repository: repo));
    await tester.pumpAndSettle();

    final sendBtn = find.byType(ElevatedButton);
    expect(sendBtn, findsOneWidget);

    await tester.tap(sendBtn);
    await tester.pumpAndSettle();

    expect(find.byType(BroadcastSheet), findsOneWidget);
  });
}