import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zawaj_app/src/data/models/activity_feed_model.dart';
import 'package:zawaj_app/src/data/models/guest_detail_model.dart' show ActivityAction;
import 'package:zawaj_app/src/data/repositories/activity_repository.dart';
import 'package:zawaj_app/src/shared/enums/app_status.dart';
import 'package:zawaj_app/src/ui/activity/providers/activity_log_provider.dart';
import 'package:zawaj_app/src/utils/failure.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

class _FakeActivityRepository implements ActivityRepository {
  _FakeActivityRepository(this.result);
  final Either<Failure, ActivityFeedPage> result;

  @override
  FutureEither<ActivityFeedPage> feed(
    String weddingId, {
    String? cursor,
    int? pageSize,
  }) async =>
      result;
}

// Fixed clock so day-bucketing is deterministic.
final _now = DateTime(2026, 9, 2, 12, 0);

ActivityLogProvider _provider(Either<Failure, ActivityFeedPage> result) =>
    ActivityLogProvider(
      weddingId: 'w1',
      repository: _FakeActivityRepository(result),
      now: () => _now,
    );

void main() {
  group('ActivityLogProvider', () {
    test('initial state is correctly initialized', () {
      final provider = _provider(const Right(ActivityFeedPage()));
      expect(provider.status, AppStatus.initial);
      expect(provider.groups, isEmpty);
      expect(provider.isEmpty, isFalse);
      expect(provider.isLoading, isFalse);
    });

    test('load buckets entries by day and maps actions to display items', () async {
      final page = ActivityFeedPage(items: [
        ActivityFeedEntry(
          id: '1',
          action: ActivityAction.guestStatusChanged,
          actorName: 'Sarah',
          guestName: 'Mariam',
          meta: const {'status': 'confirmed'},
          createdAt: DateTime(2026, 9, 2, 10, 0), // today
        ),
        ActivityFeedEntry(
          id: '2',
          action: ActivityAction.remindersSent,
          actorName: 'Sarah',
          meta: const {'count': 30},
          createdAt: DateTime(2026, 9, 2, 8, 0), // today
        ),
        ActivityFeedEntry(
          id: '3',
          action: ActivityAction.collaboratorJoined,
          actorName: 'Omar',
          createdAt: DateTime(2026, 9, 1, 18, 0), // yesterday
        ),
      ]);

      final provider = _provider(Right(page));
      await provider.load();

      expect(provider.status, AppStatus.success);
      expect(provider.groups.length, 2); // today + yesterday
      final today = provider.groups.first;
      expect(today.titleKey, 'activity.today');
      expect(today.items.length, 2);
      expect(today.items.first.type, ActivityItemType.confirmed);
      expect(today.items.first.textKey, 'activity.item_confirmed');
      expect(today.items.first.textArgs?['name'], 'Mariam');
      final reminder = today.items[1];
      expect(reminder.type, ActivityItemType.reminder);
      expect(reminder.textArgs?['count'], '30');
      expect(provider.groups[1].titleKey, 'activity.yesterday');
    });

    test('declined status maps to declined item', () async {
      final page = ActivityFeedPage(items: [
        ActivityFeedEntry(
          id: '9',
          action: ActivityAction.guestStatusChanged,
          actorName: 'Sarah',
          guestName: 'Khalid',
          meta: const {'status': 'declined'},
          createdAt: _now,
        ),
      ]);
      final provider = _provider(Right(page));
      await provider.load();
      expect(provider.groups.first.items.first.type, ActivityItemType.declined);
      expect(provider.groups.first.items.first.textKey, 'activity.item_declined');
    });

    test('empty page yields isEmpty', () async {
      final provider = _provider(const Right(ActivityFeedPage()));
      await provider.load();
      expect(provider.status, AppStatus.success);
      expect(provider.isEmpty, isTrue);
    });

    test('failure sets status to failure with message', () async {
      final provider = _provider(const Left(ServerFailure('boom')));
      await provider.load();
      expect(provider.status, AppStatus.failure);
      expect(provider.errorMessage, 'boom');
    });

    test('ActivityItem returns raw strings when provided', () {
      const item = ActivityItem(
        id: '1',
        type: ActivityItemType.exported,
        textKey: 'key_text',
        whenKey: 'key_when',
        rawText: 'Raw Activity Text',
        rawWhen: 'Raw Time Text',
      );
      expect(item.formattedText(), 'Raw Activity Text');
      expect(item.formattedWhen(), 'Raw Time Text');
    });
  });
}
