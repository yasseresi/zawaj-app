import '../data/models/wedding_stats_model.dart';
import '../data/services/api_client.dart';
import '../utils/typedefs.dart';

/// API surface for a wedding's analytics module (screen 8). Pure transport.
///
/// Backend contract: `GET /weddings/:id/stats` returns the aggregate figures;
/// `POST /weddings/:id/reminders` records a broadcast reminder to pending guests
/// and returns `{ count }`. Both under the standard `{data,error}` envelope.
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

  /// `POST /weddings/:id/reminders` → send reminders to pending guests (editor+).
  /// Returns the number of guests targeted.
  FutureEither<int> sendReminders(String weddingId) =>
      _api.post<int>(
        '/weddings/$weddingId/reminders',
        parse: (d) {
          if (d is Map && d.containsKey('count')) {
            return (d['count'] as num).toInt();
          }
          return 0;
        },
      );
}
