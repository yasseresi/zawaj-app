import '../models/activity_feed_model.dart';
import '../../services/activity_service.dart';
import '../../utils/typedefs.dart';
import 'activity_repository.dart';

/// Default [ActivityRepository] backed by [ActivityService] (live HTTP).
class ActivityRepositoryImpl implements ActivityRepository {
  ActivityRepositoryImpl({ActivityService? service})
      : _service = service ?? ActivityService.instance;

  final ActivityService _service;

  @override
  FutureEither<ActivityFeedPage> feed(
    String weddingId, {
    String? cursor,
    int? pageSize,
  }) =>
      _service.feed(weddingId, cursor: cursor, pageSize: pageSize);
}
