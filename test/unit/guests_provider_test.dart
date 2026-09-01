import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zawaj_app/src/data/models/guest_model.dart';
import 'package:zawaj_app/src/data/repositories/guest_repository.dart';
import 'package:zawaj_app/src/shared/enums/app_status.dart';
import 'package:zawaj_app/src/ui/weddings/providers/guests_provider.dart';
import 'package:zawaj_app/src/utils/failure.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

class _FakeGuestRepository implements GuestRepository {
  Either<Failure, GuestListResult>? result;
  int calls = 0;
  ({String weddingId, String? status, String? query})? lastArgs;

  @override
  FutureEither<GuestListResult> list(
    String weddingId, {
    String? status,
    String? query,
  }) async {
    calls++;
    lastArgs = (weddingId: weddingId, status: status, query: query);
    return result!;
  }

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

const _result = GuestListResult(
  items: [
    Guest(id: 'g1', fullName: 'Hind', status: RsvpStatus.confirmed),
    Guest(id: 'g2', fullName: 'Youssef', status: RsvpStatus.pending),
  ],
  counts: GuestCounts(all: 2, confirmed: 1, pending: 1),
);

void main() {
  group('GuestsProvider', () {
    late _FakeGuestRepository repo;
    late GuestsProvider provider;

    setUp(() {
      repo = _FakeGuestRepository();
      provider = GuestsProvider(weddingId: 'w1', repository: repo);
    });

    test('load success exposes guests and counts', () async {
      repo.result = const Right(_result);

      await provider.load();

      expect(provider.status, AppStatus.success);
      expect(provider.guests, hasLength(2));
      expect(provider.counts.all, 2);
      expect(provider.counts.confirmed, 1);
      expect(repo.lastArgs?.weddingId, 'w1');
      expect(repo.lastArgs?.status, isNull); // 'all' filter -> no status param
    });

    test('setFilter reloads with the status wire value', () async {
      repo.result = const Right(_result);
      await provider.load();

      await provider.setFilter(GuestFilter.confirmed);

      expect(provider.filter, GuestFilter.confirmed);
      expect(repo.lastArgs?.status, 'confirmed');
      expect(repo.calls, 2);
    });

    test('setFilter to the same value does not refetch', () async {
      repo.result = const Right(_result);
      await provider.load();

      await provider.setFilter(GuestFilter.all);

      expect(repo.calls, 1);
    });

    test('search reloads with the query', () async {
      repo.result = const Right(_result);
      await provider.load();

      await provider.search('Hind');

      expect(repo.lastArgs?.query, 'Hind');
    });

    test('failure sets the error message and status', () async {
      repo.result = const Left(NetworkFailure('offline'));

      await provider.load();

      expect(provider.status, AppStatus.failure);
      expect(provider.errorMessage, 'offline');
    });

    test('isEmpty is true only after a successful empty load', () async {
      repo.result = const Right(GuestListResult());

      expect(provider.isEmpty, isFalse); // initial
      await provider.load();

      expect(provider.isEmpty, isTrue);
    });
  });
}
