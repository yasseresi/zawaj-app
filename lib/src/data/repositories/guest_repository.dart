import '../models/guest_model.dart';
import '../../utils/typedefs.dart';

/// Data boundary for a wedding's guests. Providers depend on this interface (not
/// the service) so they can be tested with a fake.
abstract interface class GuestRepository {
  /// `GET /weddings/:id/guests` — the wedding's guests plus wedding-wide RSVP
  /// counts. [status] filters the page (`'' `= all); [query] searches full name
  /// / contact. Both are optional and applied server-side.
  FutureEither<GuestListResult> list(
    String weddingId, {
    String? status,
    String? query,
  });
}
