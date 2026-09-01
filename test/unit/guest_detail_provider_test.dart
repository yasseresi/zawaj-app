import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zawaj_app/src/data/models/guest_detail_model.dart';
import 'package:zawaj_app/src/data/models/guest_model.dart';
import 'package:zawaj_app/src/data/repositories/guest_repository.dart';
import 'package:zawaj_app/src/shared/enums/app_status.dart';
import 'package:zawaj_app/src/ui/weddings/providers/guest_detail_provider.dart';
import 'package:zawaj_app/src/utils/failure.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

class _FakeGuestRepository implements GuestRepository {
  Either<Failure, GuestDetail>? getResult;
  ({String weddingId, String guestId})? lastArgs;

  @override
  FutureEither<GuestDetail> get(String weddingId, String guestId) async {
    lastArgs = (weddingId: weddingId, guestId: guestId);
    return getResult!;
  }

  @override
  FutureEither<GuestListResult> list(String weddingId,
          {String? status, String? query}) async =>
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
  }) async =>
      throw UnimplementedError();
}

const _detail = GuestDetail(
  guest: Guest(id: 'g1', fullName: 'Maryam', status: RsvpStatus.confirmed),
  notes: [GuestNote(id: 'n1', body: 'No nuts')],
  history: [ActivityLog(id: 'a1', action: ActivityAction.guestAdded)],
);

void main() {
  group('GuestDetailProvider', () {
    late _FakeGuestRepository repo;
    late GuestDetailProvider provider;

    setUp(() {
      repo = _FakeGuestRepository();
      provider = GuestDetailProvider(
        weddingId: 'w1',
        guestId: 'g1',
        repository: repo,
      );
    });

    test('load success exposes guest, notes and history', () async {
      repo.getResult = const Right(_detail);

      await provider.load();

      expect(provider.status, AppStatus.success);
      expect(provider.detail?.guest.fullName, 'Maryam');
      expect(provider.detail?.notes, hasLength(1));
      expect(provider.detail?.history, hasLength(1));
      expect(repo.lastArgs, (weddingId: 'w1', guestId: 'g1'));
    });

    test('failure sets the error message and status', () async {
      repo.getResult = const Left(NotFoundFailure('guest not found'));

      await provider.load();

      expect(provider.status, AppStatus.failure);
      expect(provider.errorMessage, 'guest not found');
      expect(provider.detail, isNull);
    });
  });
}
