import '../data/models/wedding_model.dart';
import '../data/services/api_client.dart';
import '../utils/typedefs.dart';

/// API surface for the weddings endpoints. Pure transport: returns
/// [FutureEither] of domain objects, no [BuildContext], no session state.
///
/// Backend contract: `GET /weddings` returns `{ "items": [ WeddingListItem ] }`
/// under the standard `{data,error}` envelope (unwrapped by [ApiClient]).
class WeddingService {
  WeddingService._();
  static final WeddingService instance = WeddingService._();

  final ApiClient _api = ApiClient.instance;

  FutureEither<List<Wedding>> list() => _api.get<List<Wedding>>(
        '/weddings',
        parse: _parseItems,
      );

  /// `POST /weddings` → the created wedding (201). Only non-null optional fields
  /// are sent so the backend's `omitempty` validators apply.
  FutureEither<Wedding> create({
    required String name,
    String? eventDate,
    String? description,
  }) =>
      _api.post<Wedding>(
        '/weddings',
        body: {
          'name': name,
          if (eventDate != null) 'event_date': eventDate,
          if (description != null) 'description': description,
        },
        parse: (d) => Wedding.fromJson((d as Map).cast<String, dynamic>()),
      );

  /// `DELETE /weddings/:id` → 200 `{deleted:true}`. Owner-only (enforced
  /// server-side via RequireRole). Body is discarded.
  FutureEither<void> delete(String id) => _api.delete<void>(
        '/weddings/$id',
        parse: parseVoid,
      );

  static List<Wedding> _parseItems(dynamic data) {
    final items = (data is Map ? data['items'] : data) as List? ?? const [];
    return [
      for (final e in items)
        if (e is Map) Wedding.fromJson(e.cast<String, dynamic>()),
    ];
  }
}
