import '../models/wedding_stats_model.dart';
import '../../utils/typedefs.dart';

/// Data boundary for a wedding's analytics (screen 8). Providers depend on this
/// interface (not the service) so they can be tested with a fake.
abstract interface class StatsRepository {
  /// `GET /weddings/:id/stats` — aggregate RSVP figures for the wedding.
  FutureEither<WeddingStats> stats(String weddingId);

  /// `POST /weddings/:id/reminders` — send reminders to pending guests
  /// (editor+). Returns the number of guests targeted.
  FutureEither<int> sendReminders(String weddingId);
}
