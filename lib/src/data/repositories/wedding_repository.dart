import '../models/wedding_model.dart';
import '../../utils/typedefs.dart';

/// Data boundary for weddings. Providers depend on this interface (not the
/// service) so they can be tested with a fake.
abstract interface class WeddingRepository {
  /// `GET /weddings` — the caller's weddings, each with role + guest count,
  /// newest first.
  FutureEither<List<Wedding>> myWeddings();

  /// `POST /weddings` — create a wedding owned by the caller. [eventDate] is an
  /// optional `YYYY-MM-DD` string; [description] optional.
  FutureEither<Wedding> create({
    required String name,
    String? eventDate,
    String? description,
  });
}
