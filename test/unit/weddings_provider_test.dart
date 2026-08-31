import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zawaj_app/src/data/models/wedding_model.dart';
import 'package:zawaj_app/src/data/repositories/wedding_repository.dart';
import 'package:zawaj_app/src/shared/enums/app_status.dart';
import 'package:zawaj_app/src/ui/weddings/providers/weddings_provider.dart';
import 'package:zawaj_app/src/utils/failure.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

class _FakeWeddingRepository implements WeddingRepository {
  Either<Failure, List<Wedding>>? result;

  @override
  FutureEither<List<Wedding>> myWeddings() async => result!;

  @override
  FutureEither<Wedding> create({
    required String name,
    String? eventDate,
    String? description,
  }) async =>
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
}
