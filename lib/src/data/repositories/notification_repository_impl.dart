import '../models/app_notification_model.dart';
import '../../services/notification_service.dart';
import '../../utils/typedefs.dart';
import 'notification_repository.dart';

/// Default [NotificationRepository] backed by [NotificationService] (live HTTP).
class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({NotificationService? service})
      : _service = service ?? NotificationService.instance;

  final NotificationService _service;

  @override
  FutureEither<List<AppNotification>> list() => _service.list();

  @override
  FutureEither<int> unreadCount() => _service.unreadCount();

  @override
  FutureEither<void> markRead(String id) => _service.markRead(id);

  @override
  FutureEither<void> markAllRead() => _service.markAllRead();
}
