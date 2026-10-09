import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zawaj_app/src/data/models/wedding_model.dart';
import 'package:zawaj_app/src/data/repositories/wedding_repository.dart';
import 'package:zawaj_app/src/shared/enums/app_status.dart';
import 'package:zawaj_app/src/ui/weddings/providers/wedding_provider.dart';
import 'package:zawaj_app/src/utils/failure.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

class _FakeWeddingRepository implements WeddingRepository {
  Either<Failure, Wedding>? getResult;
  int getCalls = 0;

  @override
  FutureEither<Wedding> get(String id) async {
    getCalls++;
    return getResult!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const _initial = Wedding(
    id: 'w1',
    name: 'L&O',
    ownerId: 'u1',
    role: WeddingRole.owner,
    guestCount: 40);

void main() {
  test('cold load (no initial) fetches the wedding', () async {
    final repo = _FakeWeddingRepository()
      ..getResult = const Right(Wedding(
          id: 'w1', name: 'L&O', ownerId: 'u1', role: WeddingRole.editor));
    final p = WeddingProvider(weddingId: 'w1', repository: repo);

    expect(p.wedding, isNull);
    await p.load();

    expect(p.status, AppStatus.success);
    expect(p.wedding!.role, WeddingRole.editor);
  });

  test('shows the initial wedding at once, then adopts the fresh role',
      () async {
    final repo = _FakeWeddingRepository()
      ..getResult = const Right(Wedding(
          id: 'w1', name: 'L&O', ownerId: 'u2', role: WeddingRole.editor));
    final p =
        WeddingProvider(weddingId: 'w1', initial: _initial, repository: repo);

    expect(p.wedding, _initial);
    expect(p.status, AppStatus.success);
    await p.load();

    expect(p.wedding!.role, WeddingRole.editor);
    // GET /weddings/:id has no guest count; keep the one we had.
    expect(p.wedding!.guestCount, 40);
  });

  test('a 404 marks the wedding as not found', () async {
    final repo = _FakeWeddingRepository()
      ..getResult = const Left(NotFoundFailure('gone'));
    final p =
        WeddingProvider(weddingId: 'w1', initial: _initial, repository: repo);

    await p.load();

    expect(p.isNotFound, isTrue);
  });

  test('other failures keep the initial wedding visible', () async {
    final repo = _FakeWeddingRepository()
      ..getResult = const Left(ServerFailure('boom'));
    final p =
        WeddingProvider(weddingId: 'w1', initial: _initial, repository: repo);

    await p.load();

    expect(p.status, AppStatus.success);
    expect(p.wedding, _initial);
    expect(p.isNotFound, isFalse);
  });

  test('cold-load failure surfaces an error state', () async {
    final repo = _FakeWeddingRepository()
      ..getResult = const Left(ServerFailure('boom'));
    final p = WeddingProvider(weddingId: 'w1', repository: repo);

    await p.load();

    expect(p.status, AppStatus.failure);
    expect(p.errorMessage, 'boom');
  });

  test('applyUpdate merges a PATCH result keeping role and guest count', () {
    final p = WeddingProvider(
        weddingId: 'w1',
        initial: _initial,
        repository: _FakeWeddingRepository());

    p.applyUpdate(Wedding(
        id: 'w1',
        name: 'Renamed',
        ownerId: 'u1',
        role: WeddingRole.viewer,
        eventDate: DateTime(2026, 12, 1)));

    expect(p.wedding!.name, 'Renamed');
    expect(p.wedding!.eventDate, DateTime(2026, 12, 1));
    expect(p.wedding!.role, WeddingRole.owner);
    expect(p.wedding!.guestCount, 40);
  });
}
