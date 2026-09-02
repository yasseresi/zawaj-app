import '../data/models/activity_feed_model.dart';
import '../data/services/api_client.dart';
import '../utils/typedefs.dart';

/// API surface for a wedding's activity feed (screen 9). Pure transport: returns
/// a [FutureEither] of the domain page, no [BuildContext], no session state.
///
/// Backend contract: `GET /weddings/:id/activity` returns
/// `{ items, next_cursor }` under the standard `{data,error}` envelope. Each
/// item is enriched with `actor_name` and (for guest-scoped entries)
/// `guest_name`, plus action-specific `meta`.
class ActivityService {
  ActivityService._();
  static final ActivityService instance = ActivityService._();

  final ApiClient _api = ApiClient.instance;

  /// Lists a wedding's activity newest-first. [cursor] is the opaque
  /// `next_cursor` from a previous page (omit for the first page); [pageSize]
  /// caps the page.
  FutureEither<ActivityFeedPage> feed(
    String weddingId, {
    String? cursor,
    int? pageSize,
  }) =>
      _api.get<ActivityFeedPage>(
        '/weddings/$weddingId/activity',
        query: {
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
          if (pageSize != null) 'page_size': pageSize,
        },
        parse: ActivityFeedPage.fromJson,
      );
}
