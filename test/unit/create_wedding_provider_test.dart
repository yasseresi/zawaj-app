import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zawaj_app/src/data/models/wedding_member_model.dart';
import 'package:zawaj_app/src/data/models/wedding_model.dart';
import 'package:zawaj_app/src/data/repositories/wedding_repository.dart';
import 'package:zawaj_app/src/shared/enums/app_status.dart';
import 'package:zawaj_app/src/ui/weddings/providers/create_wedding_provider.dart';
import 'package:zawaj_app/src/utils/failure.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

class _FakeWeddingRepository implements WeddingRepository {
  Either<Failure, Wedding>? createResult;
  ({String name, String? eventDate, String? description})? lastArgs;

  @override
  FutureEither<List<Wedding>> myWeddings() async => throw UnimplementedError();

  @override
  FutureEither<Wedding> create({
    required String name,
    String? eventDate,
    String? description,
  }) async {
    lastArgs = (name: name, eventDate: eventDate, description: description);
    return createResult!;
  }

  @override
  FutureEither<void> delete(String id) async => throw UnimplementedError();

  @override
  FutureEither<List<WeddingMember>> members(String id) async =>
      throw UnimplementedError();

  @override
  FutureEither<void> setMemberRole(String id, String userId, String role) async =>
      throw UnimplementedError();

  @override
  FutureEither<void> removeMember(String id, String userId) async =>
      throw UnimplementedError();
}

const _created = Wedding(
  id: 'w1',
  name: 'Leila & Karim',
  ownerId: 'u1',
  role: WeddingRole.owner,
);

void main() {
  group('CreateWeddingProvider.submit', () {
    late _FakeWeddingRepository repo;
    late CreateWeddingProvider provider;

    setUp(() {
      repo = _FakeWeddingRepository();
      provider = CreateWeddingProvider(repository: repo);
    });

    test('success reports success and exposes the created wedding', () async {
      repo.createResult = const Right(_created);

      final ok = await provider.submit(name: 'Leila & Karim');

      expect(ok, isTrue);
      expect(provider.status, AppStatus.success);
      expect(provider.created, _created);
      expect(repo.lastArgs?.name, 'Leila & Karim');
    });

    test('blank/empty optional fields are passed as null, not empty strings',
        () async {
      repo.createResult = const Right(_created);

      await provider.submit(name: 'X', eventDate: '', description: '   ');

      expect(repo.lastArgs?.eventDate, isNull);
      expect(repo.lastArgs?.description, isNull);
    });

    test('failure sets the error message and returns false', () async {
      repo.createResult = const Left(ValidationFailure('name is required'));

      final ok = await provider.submit(name: '');

      expect(ok, isFalse);
      expect(provider.status, AppStatus.failure);
      expect(provider.errorMessage, 'name is required');
    });
  });
}
