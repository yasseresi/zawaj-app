import '../models/app_notification_model.dart';
import '../../utils/typedefs.dart';

/// Data boundary for the current user's notification feed. Providers depend on
/// this interface (not the service) so they can be tested with a fake.
abstract interface class NotificationRepository {
  /// `GET /notifications` — the caller's notifications, newest first.
  FutureEither<List<AppNotification>> list();

  /// `GET /notifications/unread_count` — number of unread notifications.
  FutureEither<int> unreadCount();

  /// `PATCH /notifications/:id/read` — mark one read.
  FutureEither<void> markRead(String id);

  /// `POST /notifications/read_all` — mark all read.
  FutureEither<void> markAllRead();
}
