import 'package:flutter_test/flutter_test.dart';
import 'package:zawaj_app/src/shared/enums/app_status.dart';
import 'package:zawaj_app/src/ui/activity/providers/activity_log_provider.dart';

void main() {
  group('ActivityLogProvider', () {
    late ActivityLogProvider provider;

    setUp(() {
      provider = ActivityLogProvider(weddingId: 'w1');
    });

    test('initial state is correctly initialized', () {
      expect(provider.status, AppStatus.initial);
      expect(provider.groups, isEmpty);
      expect(provider.errorMessage, isNull);
      expect(provider.isEmpty, isFalse);
      expect(provider.isLoading, isFalse);
    });

    test('load populates default activity groups and sets status to success', () async {
      await provider.load();

      expect(provider.status, AppStatus.success);
      expect(provider.groups, isNotEmpty);
      expect(provider.groups.length, 3);
      expect(provider.isEmpty, isFalse);
      expect(provider.isLoading, isFalse);
    });

    test('setGroups updates groups and status', () {
      const customGroups = [
        ActivityGroup(
          titleKey: 'activity.today',
          items: [
            ActivityItem(
              id: '100',
              type: ActivityItemType.confirmed,
              textKey: 'Confirmed item',
              whenKey: 'Today',
            ),
          ],
        ),
      ];

      provider.setGroups(customGroups);

      expect(provider.status, AppStatus.success);
      expect(provider.groups, customGroups);
      expect(provider.groups.length, 1);
      expect(provider.isEmpty, isFalse);
    });

    test('isEmpty returns true when loaded with empty groups', () {
      provider.setGroups(const []);

      expect(provider.status, AppStatus.success);
      expect(provider.isEmpty, isTrue);
    });

    test('setError updates status to failure and sets errorMessage', () {
      provider.setError('Network error');

      expect(provider.status, AppStatus.failure);
      expect(provider.errorMessage, 'Network error');
      expect(provider.isEmpty, isFalse);
    });

    test('ActivityItem formattedText and formattedWhen return raw strings when provided', () {
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
