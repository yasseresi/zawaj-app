import '../models/wedding_stats_model.dart';
import '../../services/stats_service.dart';
import '../../utils/typedefs.dart';
import 'stats_repository.dart';

/// Default [StatsRepository] backed by [StatsService] (live HTTP).
class StatsRepositoryImpl implements StatsRepository {
  StatsRepositoryImpl({StatsService? service})
      : _service = service ?? StatsService.instance;

  final StatsService _service;

  @override
  FutureEither<WeddingStats> stats(String weddingId) => _service.stats(weddingId);

  @override
  FutureEither<int> sendReminders(String weddingId) =>
      _service.sendReminders(weddingId);
}
