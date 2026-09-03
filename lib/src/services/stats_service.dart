import '../data/models/wedding_stats_model.dart';
import '../data/services/api_client.dart';
import '../utils/typedefs.dart';

/// API surface for a wedding's analytics module (screen 8). Pure transport.
///
/// Backend contract: `GET /weddings/:id/stats` returns the aggregate figures
/// under the standard `{data,error}` envelope.
class StatsService {
  StatsService._();
  static final StatsService instance = StatsService._();

  final ApiClient _api = ApiClient.instance;

  /// `GET /weddings/:id/stats` → aggregate RSVP figures.
  FutureEither<WeddingStats> stats(String weddingId) =>
      _api.get<WeddingStats>(
        '/weddings/$weddingId/stats',
        parse: WeddingStats.fromJson,
      );
}
