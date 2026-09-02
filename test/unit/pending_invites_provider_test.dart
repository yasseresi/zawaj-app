import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zawaj_app/src/data/repositories/invite_repository.dart';
import 'package:zawaj_app/src/shared/enums/app_status.dart';
import 'package:zawaj_app/src/ui/invites/providers/pending_invites_provider.dart';
import 'package:zawaj_app/src/utils/failure.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

class _FakeInviteRepository implements InviteRepository {
  _FakeInviteRepository({
    this.listResult = const Right([]),
    this.acceptResult = const Right(null),
    this.declineResult = const Right(null),
  });

  Either<Failure, List<PendingInvite>> listResult;
  Either<Failure, void> acceptResult;
  Either<Failure, void> declineResult;
  final List<String> accepted = [];
  final List<String> declined = [];

  @override
  FutureEither<List<PendingInvite>> list() async => listResult;

  @override
  FutureEither<void> accept(String inviteId) async {
    accepted.add(inviteId);
    return acceptResult;
  }

  @override
  FutureEither<void> decline(String inviteId) async {
    declined.add(inviteId);
    return declineResult;
  }
}

const _invites = [
  PendingInvite(id: '1', event: 'L&O', sender: 'Sarah', date: '2026-09-01'),
  PendingInvite(id: '2', event: 'R', sender: 'Hind', date: '2026-08-30'),
];

void main() {
  group('PendingInvitesProvider', () {
    test('initial state is correctly initialized', () {
      final provider = PendingInvitesProvider(repository: _FakeInviteRepository());
      expect(provider.status, AppStatus.initial);
      expect(provider.invites, isEmpty);
      expect(provider.isEmpty, isFalse);
    });

    test('load populates invites from the repository', () async {
      final provider = PendingInvitesProvider(
        repository: _FakeInviteRepository(listResult: const Right(_invites)),
      );
      await provider.load();
      expect(provider.status, AppStatus.success);
      expect(provider.invites.length, 2);
    });

    test('load failure surfaces the message', () async {
      final provider = PendingInvitesProvider(
        repository: _FakeInviteRepository(listResult: const Left(ServerFailure('boom'))),
      );
      await provider.load();
      expect(provider.status, AppStatus.failure);
      expect(provider.errorMessage, 'boom');
    });

    test('acceptInvite removes invite on success', () async {
      final repo = _FakeInviteRepository(listResult: const Right(_invites));
      final provider = PendingInvitesProvider(repository: repo);
      await provider.load();

      final future = provider.acceptInvite('1');
      expect(provider.actionLoadingId, '1');
      final success = await future;

      expect(success, isTrue);
      expect(repo.accepted, ['1']);
      expect(provider.actionLoadingId, isNull);
      expect(provider.invites.any((i) => i.id == '1'), isFalse);
      expect(provider.invites.length, 1);
    });

    test('declineInvite removes invite on success', () async {
      final repo = _FakeInviteRepository(
        listResult: const Right(_invites),
        declineResult: const Right(null),
      );
      final provider = PendingInvitesProvider(repository: repo);
      await provider.load();

      final success = await provider.declineInvite('2');
      expect(success, isTrue);
      expect(repo.declined, ['2']);
      expect(provider.invites.any((i) => i.id == '2'), isFalse);
    });

    test('acceptInvite keeps invite and surfaces error on failure', () async {
      final repo = _FakeInviteRepository(
        listResult: const Right(_invites),
        acceptResult: const Left(NetworkFailure('offline')),
      );
      final provider = PendingInvitesProvider(repository: repo);
      await provider.load();

      final success = await provider.acceptInvite('1');
      expect(success, isFalse);
      expect(provider.errorMessage, 'offline');
      expect(provider.invites.length, 2); // unchanged
    });

    test('isEmpty is true after loading an empty list', () async {
      final provider = PendingInvitesProvider(
        repository: _FakeInviteRepository(listResult: const Right([])),
      );
      await provider.load();
      expect(provider.isEmpty, isTrue);
    });

    test('PendingInvite avatarInitial computes correctly', () {
      const withInitial = PendingInvite(
          id: '1', event: 'E', sender: 'Sarah', date: 'x', initial: 'S');
      expect(withInitial.avatarInitial, 'S');
      const fallback = PendingInvite(id: '2', event: 'E', sender: 'Fatima', date: 'x');
      expect(fallback.avatarInitial, 'F');
    });

    test('fromJson maps the enriched backend shape', () {
      final inv = PendingInvite.fromJson(const {
        'id': 'abc',
        'wedding_id': 'w1',
        'wedding_name': 'L&O',
        'inviter_name': 'Sarah',
        'role': 'editor',
        'created_at': '2026-09-02T10:00:00Z',
      });
      expect(inv.event, 'L&O');
      expect(inv.sender, 'Sarah');
      expect(inv.role, 'editor');
      expect(inv.weddingId, 'w1');
      expect(inv.date, startsWith('2026-09-02'));
    });
  });
}
