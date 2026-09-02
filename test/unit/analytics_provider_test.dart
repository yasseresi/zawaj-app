import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zawaj_app/src/data/models/wedding_stats_model.dart';
import 'package:zawaj_app/src/data/repositories/stats_repository.dart';
import 'package:zawaj_app/src/shared/enums/app_status.dart';
import 'package:zawaj_app/src/ui/analytics/providers/analytics_provider.dart';
import 'package:zawaj_app/src/utils/failure.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

class _MockStatsRepository implements StatsRepository {
  Either<Failure, WeddingStats>? statsResult;
  Either<Failure, int>? sendRemindersResult;
  int statsCalls = 0;
  int sendRemindersCalls = 0;

  @override
  FutureEither<WeddingStats> stats(String weddingId) async {
    statsCalls++;
    return statsResult!;
  }

  @override
  FutureEither<int> sendReminders(String weddingId) async {
    sendRemindersCalls++;
    return sendRemindersResult!;
  }
}

const _sampleResult = WeddingStats(
  totalGuests: 245,
  confirmed: 142,
  declined: 24,
  pending: 79,
);

void main() {
  group('AnalyticsProvider', () {
    late _MockStatsRepository repo;
    late AnalyticsProvider provider;

    setUp(() {
      repo = _MockStatsRepository();
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
      repo.statsResult = const Right(_sampleResult);

      await provider.load();

      expect(provider.status, AppStatus.success);
      expect(provider.totalGuests, 245);
      expect(provider.confirmedCount, 142);
      expect(provider.declinedCount, 24);
      expect(provider.pendingCount, 79);
      expect(provider.isEmpty, isFalse);
      expect(repo.statsCalls, 1);
    });

    test('load failure sets status failure and error message', () async {
      repo.statsResult = const Left(ServerFailure('Failed to fetch'));

      await provider.load();

      expect(provider.status, AppStatus.failure);
      expect(provider.errorMessage, 'Failed to fetch');
    });

    test('isEmpty is true after successful load with 0 guests', () async {
      repo.statsResult = const Right(WeddingStats());

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
