import 'package:flutter_test/flutter_test.dart';
import 'package:zawaj_app/src/shared/enums/app_status.dart';
import 'package:zawaj_app/src/ui/invites/providers/pending_invites_provider.dart';

void main() {
  group('PendingInvitesProvider', () {
    late PendingInvitesProvider provider;

    setUp(() {
      provider = PendingInvitesProvider();
    });

    test('initial state is correctly initialized', () {
      expect(provider.status, AppStatus.initial);
      expect(provider.invites, isEmpty);
      expect(provider.actionLoadingId, isNull);
      expect(provider.errorMessage, isNull);
      expect(provider.isEmpty, isFalse);
      expect(provider.isLoading, isFalse);
    });

    test('load populates default invites and sets status to success', () async {
      await provider.load();

      expect(provider.status, AppStatus.success);
      expect(provider.invites, isNotEmpty);
      expect(provider.invites.length, 3);
      expect(provider.isEmpty, isFalse);
      expect(provider.isLoading, isFalse);
    });

    test('acceptInvite removes invite and clears actionLoadingId', () async {
      await provider.load();

      final future = provider.acceptInvite('1');
      expect(provider.actionLoadingId, '1');

      final success = await future;
      expect(success, isTrue);
      expect(provider.actionLoadingId, isNull);
      expect(provider.invites.any((i) => i.id == '1'), isFalse);
      expect(provider.invites.length, 2);
    });

    test('declineInvite removes invite and clears actionLoadingId', () async {
      await provider.load();

      final future = provider.declineInvite('2');
      expect(provider.actionLoadingId, '2');

      final success = await future;
      expect(success, isTrue);
      expect(provider.actionLoadingId, isNull);
      expect(provider.invites.any((i) => i.id == '2'), isFalse);
      expect(provider.invites.length, 2);
    });

    test('setInvites updates invites and status', () {
      const customInvites = [
        PendingInvite(
          id: '10',
          event: 'Test Event',
          sender: 'John Doe',
          date: '1 day ago',
        ),
      ];

      provider.setInvites(customInvites);

      expect(provider.status, AppStatus.success);
      expect(provider.invites, customInvites);
      expect(provider.invites.length, 1);
      expect(provider.isEmpty, isFalse);
    });

    test('isEmpty returns true when loaded with empty invites', () {
      provider.setInvites(const []);

      expect(provider.status, AppStatus.success);
      expect(provider.isEmpty, isTrue);
    });

    test('setError updates status to failure and sets errorMessage', () {
      provider.setError('Failed to fetch');

      expect(provider.status, AppStatus.failure);
      expect(provider.errorMessage, 'Failed to fetch');
      expect(provider.isEmpty, isFalse);
    });

    test('PendingInvite avatarInitial computes correctly', () {
      const customInitial = PendingInvite(
        id: '1',
        event: 'Event',
        sender: 'Sarah',
        date: 'Today',
        initial: 'S',
      );
      expect(customInitial.avatarInitial, 'S');

      const fallbackInitial = PendingInvite(
        id: '2',
        event: 'Event',
        sender: 'Fatima',
        date: 'Today',
      );
      expect(fallbackInitial.avatarInitial, 'F');
    });
  });
}
