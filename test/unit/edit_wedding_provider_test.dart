import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zawaj_app/src/data/models/wedding_model.dart';
import 'package:zawaj_app/src/data/repositories/wedding_repository.dart';
import 'package:zawaj_app/src/ui/weddings/providers/edit_wedding_provider.dart';
import 'package:zawaj_app/src/utils/failure.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

class _FakeWeddingRepository implements WeddingRepository {
  Either<Failure, Wedding>? updateResult;
  final calls = <({String? name, String? eventDate, String? description})>[];

  @override
  FutureEither<Wedding> update(String id,
      {String? name, String? eventDate, String? description}) async {
    calls.add((name: name, eventDate: eventDate, description: description));
    return updateResult!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final _wedding = Wedding(
  id: 'w1',
  name: 'Leila & Omar',
  ownerId: 'u1',
  role: WeddingRole.owner,
  eventDate: DateTime(2026, 12, 1),
  description: 'Hall A',
);

void main() {
  late _FakeWeddingRepository repo;
  late EditWeddingProvider provider;

  setUp(() {
    repo = _FakeWeddingRepository();
    provider = EditWeddingProvider(wedding: _wedding, repository: repo);
  });

  test('isDirty is false for the original values (ignoring whitespace)', () {
    expect(
        provider.isDirty(
            name: ' Leila & Omar ',
            date: DateTime(2026, 12, 1),
            description: 'Hall A'),
        isFalse);
  });

  test('sends only the changed date', () async {
    repo.updateResult = Right(_wedding);

    final saved = await provider.save(
        name: 'Leila & Omar',
        date: DateTime(2027, 1, 2),
        description: 'Hall A');

    expect(saved, isNotNull);
    expect(repo.calls.single,
        (name: null, eventDate: '2027-01-02', description: null));
  });

  test('sends a trimmed name and an empty description to clear it', () async {
    repo.updateResult = Right(_wedding);

    await provider.save(
        name: ' L & O ', date: DateTime(2026, 12, 1), description: '  ');

    expect(
        repo.calls.single, (name: 'L & O', eventDate: null, description: ''));
  });

  test('makes no request when nothing changed', () async {
    final saved = await provider.save(
        name: 'Leila & Omar',
        date: DateTime(2026, 12, 1),
        description: 'Hall A');

    expect(saved, _wedding);
    expect(repo.calls, isEmpty);
  });

  test('returns null and exposes the error on failure', () async {
    repo.updateResult = const Left(ForbiddenFailure('not owner'));

    final saved = await provider.save(
        name: 'New', date: DateTime(2026, 12, 1), description: 'Hall A');

    expect(saved, isNull);
    expect(provider.errorMessage, isNotNull);
    expect(provider.isSaving, isFalse);
  });
}
