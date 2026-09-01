import '../data/models/guest_model.dart';
import '../data/services/api_client.dart';
import '../utils/typedefs.dart';

/// API surface for a wedding's guest endpoints. Pure transport: returns
/// [FutureEither] of domain objects, no [BuildContext], no session state.
///
/// Backend contract: `GET /weddings/:id/guests` returns `{ items, counts }`
/// under the standard `{data,error}` envelope (unwrapped by [ApiClient]).
class GuestService {
  GuestService._();
  static final GuestService instance = GuestService._();

  final ApiClient _api = ApiClient.instance;

  /// Lists guests for [weddingId]. [status] (`pending|confirmed|declined`) and
  /// [query] are sent only when non-empty so the backend's optional filters
  /// apply.
  FutureEither<GuestListResult> list(
    String weddingId, {
    String? status,
    String? query,
  }) =>
      _api.get<GuestListResult>(
        '/weddings/$weddingId/guests',
        query: {
          if (status != null && status.isNotEmpty) 'status': status,
          if (query != null && query.isNotEmpty) 'q': query,
        },
        parse: GuestListResult.fromJson,
      );
}
