import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zawaj_app/src/data/models/wedding_member_model.dart';
import 'package:zawaj_app/src/data/models/invite_link_model.dart';
import 'package:zawaj_app/src/data/models/wedding_model.dart';
import 'package:zawaj_app/src/data/repositories/wedding_repository.dart';
import 'package:zawaj_app/src/shared/enums/app_status.dart';
import 'package:zawaj_app/src/ui/weddings/providers/weddings_provider.dart';
import 'package:zawaj_app/src/utils/failure.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

class _FakeWeddingRepository implements WeddingRepository {
  @override
  FutureEither<void> transferOwnership(String id, String userId) async =>
      throw UnimplementedError();

  @override
  FutureEither<InviteLink> createInviteLink(String id, String role) =>
      throw UnimplementedError();
  @override
  FutureEither<List<InviteLink>> listInviteLinks(String id) =>
      throw UnimplementedError();
  @override
  FutureEither<void> revokeInviteLink(String id, String linkId) =>
      throw UnimplementedError();
  @override
  FutureEither<InvitePreview> previewInvite(String token) =>
      throw UnimplementedError();
  @override
  FutureEither<InvitePreview> acceptInviteLink(String token) =>
      throw UnimplementedError();
  Either<Failure, List<Wedding>>? result;
  Either<Failure, void>? deleteResult;
  final List<String> deletedIds = [];
  Either<Failure, Wedding>? getResult;

  @override
  FutureEither<Wedding> get(String id) async => getResult!;

  @override
  FutureEither<Wedding> update(String id,
          {String? name, String? eventDate, String? description}) async =>
      throw UnimplementedError();

  @override
  FutureEither<List<Wedding>> myWeddings() async => result!;

  @override
  FutureEither<Wedding> create({
    required String name,
    String? eventDate,
    String? description,
  }) async =>
      throw UnimplementedError();

  @override
  FutureEither<void> delete(String id) async {
    deletedIds.add(id);
    return deleteResult ?? const Right(null);
  }

  @override
  FutureEither<List<WeddingMember>> members(String id) async =>
      throw UnimplementedError();

  @override
  FutureEither<void> setMemberRole(
          String id, String userId, String role) async =>
      throw UnimplementedError();

  @override
  FutureEither<void> removeMember(String id, String userId) async =>
      throw UnimplementedError();
}

const _wedding = Wedding(
  id: 'w1',
  name: 'Leila & Karim',
  ownerId: 'u1',
  role: WeddingRole.owner,
  guestCount: 42,
);

void main() {
  group('WeddingsProvider.load', () {
    late _FakeWeddingRepository repo;
    late WeddingsProvider provider;

    setUp(() {
      repo = _FakeWeddingRepository();
      provider = WeddingsProvider(repository: repo);
    });

    test('success populates the list and reports success', () async {
      repo.result = const Right([_wedding]);

      await provider.load();

      expect(provider.status, AppStatus.success);
      expect(provider.weddings, [_wedding]);
      expect(provider.isEmpty, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('an empty result is success but flags isEmpty', () async {
      repo.result = const Right([]);

      await provider.load();

      expect(provider.status, AppStatus.success);
      expect(provider.isEmpty, isTrue);
    });

    test('failure sets the error message and status', () async {
      repo.result = const Left(ServerFailure('boom'));

      await provider.load();

      expect(provider.status, AppStatus.failure);
      expect(provider.errorMessage, 'boom');
      expect(provider.weddings, isEmpty);
    });
  });

  group('WeddingsProvider.delete', () {
    late _FakeWeddingRepository repo;
    late WeddingsProvider provider;

    setUp(() {
      repo = _FakeWeddingRepository();
      provider = WeddingsProvider(repository: repo);
    });

    test('success drops the row and flips to empty when none remain', () async {
      repo.result = const Right([_wedding]);
      await provider.load();

      final ok = await provider.delete('w1');

      expect(ok, isTrue);
      expect(repo.deletedIds, ['w1']);
      expect(provider.weddings, isEmpty);
      expect(provider.isEmpty, isTrue);
    });

    test('failure keeps the list and surfaces the error', () async {
      repo.result = const Right([_wedding]);
      await provider.load();
      repo.deleteResult = const Left(ServerFailure('nope'));

      final ok = await provider.delete('w1');

      expect(ok, isFalse);
      expect(provider.weddings, [_wedding]);
      expect(provider.errorMessage, 'nope');
    });
  });

  group('single-wedding sync', () {
    const cached = Wedding(
        id: 'w1', name: 'Old', ownerId: 'u1', role: WeddingRole.owner, guestCount: 12);
    const other = Wedding(id: 'w2', name: 'Other', ownerId: 'u2', role: WeddingRole.viewer);

    Future<WeddingsProvider> loaded(_FakeWeddingRepository repo) async {
      repo.result = const Right([cached, other]);
      final p = WeddingsProvider(repository: repo);
      await p.load();
      return p;
    }

    test('refresh replaces the cached item but keeps its guest count', () async {
      final repo = _FakeWeddingRepository();
      final p = await loaded(repo);
      repo.getResult = const Right(Wedding(
          id: 'w1', name: 'New', ownerId: 'u1', role: WeddingRole.editor));

      final result = await p.refresh('w1');

      expect(result.isRight(), isTrue);
      final w = p.weddingById('w1')!;
      expect(w.name, 'New');
      expect(w.role, WeddingRole.editor);
      expect(w.guestCount, 12);
      expect(p.weddings.map((e) => e.id), ['w1', 'w2']);
    });

    test('refresh inserts a wedding missing from the list', () async {
      final repo = _FakeWeddingRepository();
      final p = await loaded(repo);
      repo.getResult = const Right(Wedding(
          id: 'w9', name: 'Shared', ownerId: 'u3', role: WeddingRole.editor));

      await p.refresh('w9');

      expect(p.weddingById('w9')?.name, 'Shared');
      expect(p.weddings.first.id, 'w9');
    });

    test('refresh drops the wedding on 404 (deleted or access revoked)', () async {
      final repo = _FakeWeddingRepository();
      final p = await loaded(repo);
      repo.getResult = const Left(NotFoundFailure('gone'));

      final result = await p.refresh('w1');

      expect(result.isLeft(), isTrue);
      expect(p.weddingById('w1'), isNull);
    });

    test('refresh keeps the cached item on other failures', () async {
      final repo = _FakeWeddingRepository();
      final p = await loaded(repo);
      repo.getResult = const Left(ServerFailure('boom'));

      await p.refresh('w1');

      expect(p.weddingById('w1'), cached);
    });

    test('applyUpdate merges edited fields and keeps role and guest count', () async {
      final repo = _FakeWeddingRepository();
      final p = await loaded(repo);

      // PATCH returns the bare wedding: no my_role (parses as viewer), no count.
      p.applyUpdate(Wedding(
          id: 'w1',
          name: 'Renamed',
          ownerId: 'u1',
          role: WeddingRole.viewer,
          eventDate: DateTime(2026, 12, 1),
          description: 'Hall B'));

      final w = p.weddingById('w1')!;
      expect(w.name, 'Renamed');
      expect(w.eventDate, DateTime(2026, 12, 1));
      expect(w.description, 'Hall B');
      expect(w.role, WeddingRole.owner);
      expect(w.guestCount, 12);
    });
  });
}
