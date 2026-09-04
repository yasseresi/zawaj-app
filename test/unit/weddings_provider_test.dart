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
  FutureEither<InviteLink> createInviteLink(String id, String role) =>
      throw UnimplementedError();
  @override
  FutureEither<List<InviteLink>> listInviteLinks(String id) =>
      throw UnimplementedError();
  @override
  FutureEither<void> revokeInviteLink(String id, String linkId) =>
      throw UnimplementedError();
  Either<Failure, List<Wedding>>? result;
  Either<Failure, void>? deleteResult;
  final List<String> deletedIds = [];

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
}
