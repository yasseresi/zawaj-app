import '../models/activity_feed_model.dart';
import '../../utils/typedefs.dart';

/// Data boundary for a wedding's activity feed. Providers depend on this
/// interface (not the service) so they can be tested with a fake.
abstract interface class ActivityRepository {
  /// `GET /weddings/:id/activity` — a page of the wedding's activity
  /// newest-first. [cursor] pages via the previous response's `next_cursor`;
  /// [pageSize] caps the page.
  FutureEither<ActivityFeedPage> feed(
    String weddingId, {
    String? cursor,
    int? pageSize,
  });
}
