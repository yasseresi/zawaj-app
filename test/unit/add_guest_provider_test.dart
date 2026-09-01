import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zawaj_app/src/data/models/guest_detail_model.dart';
import 'package:zawaj_app/src/data/models/guest_model.dart';
import 'package:zawaj_app/src/data/repositories/guest_repository.dart';
import 'package:zawaj_app/src/shared/enums/app_status.dart';
import 'package:zawaj_app/src/ui/weddings/providers/add_guest_provider.dart';
import 'package:zawaj_app/src/utils/failure.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

class _FakeGuestRepository implements GuestRepository {
  Either<Failure, Guest>? createResult;
  ({
    String weddingId,
    String fullName,
    String? contact,
    String? status,
    int? companions,
    String? note,
  })? lastArgs;

  @override
  FutureEither<GuestListResult> list(
    String weddingId, {
    String? status,
    String? query,
  }) async =>
      throw UnimplementedError();

  @override
  FutureEither<GuestDetail> get(String weddingId, String guestId) async =>
      throw UnimplementedError();

  @override
  FutureEither<Guest> setStatus(
          String weddingId, String guestId, String status) async =>
      throw UnimplementedError();

  @override
  FutureEither<GuestNote> addNote(
          String weddingId, String guestId, String body) async =>
      throw UnimplementedError();

  @override
  FutureEither<Guest> create(
    String weddingId, {
    required String fullName,
    String? contact,
    String? relationship,
    String? status,
    int? companions,
    String? tableLabel,
    String? meal,
    String? note,
  }) async {
    lastArgs = (
      weddingId: weddingId,
      fullName: fullName,
      contact: contact,
      status: status,
      companions: companions,
      note: note,
    );
    return createResult!;
  }
}

const _created = Guest(id: 'g1', fullName: 'Maryam', status: RsvpStatus.confirmed);

void main() {
  group('AddGuestProvider.submit', () {
    late _FakeGuestRepository repo;
    late AddGuestProvider provider;

    setUp(() {
      repo = _FakeGuestRepository();
      provider = AddGuestProvider(weddingId: 'w1', repository: repo);
    });

    test('success reports success and exposes the created guest', () async {
      repo.createResult = const Right(_created);

      final ok = await provider.submit(
        fullName: 'Maryam',
        contact: 'maryam@example.com',
        status: RsvpStatus.confirmed,
        companions: 2,
      );

      expect(ok, isTrue);
      expect(provider.status, AppStatus.success);
      expect(provider.created, _created);
      expect(repo.lastArgs?.weddingId, 'w1');
      expect(repo.lastArgs?.fullName, 'Maryam');
      expect(repo.lastArgs?.status, 'confirmed');
      expect(repo.lastArgs?.companions, 2);
    });

    test('blank optional fields are passed as null, not empty strings', () async {
      repo.createResult = const Right(_created);

      await provider.submit(fullName: 'X', contact: '  ', note: '');

      expect(repo.lastArgs?.contact, isNull);
      expect(repo.lastArgs?.note, isNull);
    });

    test('failure sets the error message and returns false', () async {
      repo.createResult = const Left(ValidationFailure('full_name is required'));

      final ok = await provider.submit(fullName: '');

      expect(ok, isFalse);
      expect(provider.status, AppStatus.failure);
      expect(provider.errorMessage, 'full_name is required');
    });
  });
}
