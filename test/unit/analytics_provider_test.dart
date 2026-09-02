import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zawaj_app/src/data/models/guest_detail_model.dart';
import 'package:zawaj_app/src/data/models/guest_model.dart';
import 'package:zawaj_app/src/data/repositories/guest_repository.dart';
import 'package:zawaj_app/src/shared/enums/app_status.dart';
import 'package:zawaj_app/src/ui/analytics/providers/analytics_provider.dart';
import 'package:zawaj_app/src/utils/failure.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

class _MockGuestRepository implements GuestRepository {
  Either<Failure, GuestListResult>? listResult;
  Either<Failure, int>? sendRemindersResult;
  int listCalls = 0;
  int sendRemindersCalls = 0;

  @override
  FutureEither<GuestListResult> list(
    String weddingId, {
    String? status,
    String? query,
  }) async {
    listCalls++;
    return listResult!;
  }

  @override
  FutureEither<int> sendReminders(String weddingId) async {
    sendRemindersCalls++;
    return sendRemindersResult!;
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
}

const _sampleResult = GuestListResult(
  items: [],
  counts: GuestCounts(
    all: 245,
    confirmed: 142,
    declined: 24,
    pending: 79,
  ),
);

void main() {
  group('AnalyticsProvider', () {
    late _MockGuestRepository repo;
    late AnalyticsProvider provider;

    setUp(() {
      repo = _MockGuestRepository();
      provider = AnalyticsProvider(weddingId: 'w1', repository: repo);
    });

    test('initial state is correctly initialized', () {
      expect(provider.status, AppStatus.initial);
      expect(provider.broadcastState, BroadcastState.idle);
      expect(provider.totalGuests, 0);
      expect(provider.confirmedCount, 0);
      expect(provider.pendingCount, 0);
      expect(provider.declinedCount, 0);
      expect(provider.isEmpty, isFalse);
    });

    test('load success exposes counts and updates status', () async {
      repo.listResult = const Right(_sampleResult);

      await provider.load();

      expect(provider.status, AppStatus.success);
      expect(provider.totalGuests, 245);
      expect(provider.confirmedCount, 142);
      expect(provider.declinedCount, 24);
      expect(provider.pendingCount, 79);
      expect(provider.isEmpty, isFalse);
      expect(repo.listCalls, 1);
    });

    test('load failure sets status failure and error message', () async {
      repo.listResult = const Left(ServerFailure('Failed to fetch'));

      await provider.load();

      expect(provider.status, AppStatus.failure);
      expect(provider.errorMessage, 'Failed to fetch');
    });

    test('isEmpty is true after successful load with 0 guests', () async {
      repo.listResult = const Right(GuestListResult());

      await provider.load();

      expect(provider.status, AppStatus.success);
      expect(provider.isEmpty, isTrue);
    });

    test('broadcast flow state transitions', () async {
      repo.sendRemindersResult = const Right(30);

      provider.openBroadcastConfirm();
      expect(provider.broadcastState, BroadcastState.confirm);

      provider.cancelBroadcast();
      expect(provider.broadcastState, BroadcastState.idle);

      provider.openBroadcastConfirm();
      await provider.sendReminders();
      expect(provider.broadcastState, BroadcastState.success);
      expect(provider.lastSentCount, 30);
      expect(repo.sendRemindersCalls, 1);

      provider.dismissBroadcastResult();
      expect(provider.broadcastState, BroadcastState.idle);
    });

    test('sendReminders failure sets error state', () async {
      repo.sendRemindersResult = const Left(NetworkFailure('Connection error'));

      provider.openBroadcastConfirm();
      await provider.sendReminders();

      expect(provider.broadcastState, BroadcastState.error);
      expect(provider.errorMessage, 'Connection error');
    });
  });
}
