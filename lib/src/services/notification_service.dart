import '../data/models/app_notification_model.dart';
import '../data/services/api_client.dart';
import '../utils/typedefs.dart';

/// API surface for the current user's notification feed. Pure transport.
///
/// Backend contract (all under the `{data,error}` envelope):
/// - `GET /notifications` → `{ items, next_cursor }`
/// - `GET /notifications/unread_count` → `{ count }`
/// - `PATCH /notifications/:id/read` → marks one read
/// - `POST /notifications/read_all` → marks all read
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final ApiClient _api = ApiClient.instance;

  /// `GET /notifications` → the caller's notifications, newest first.
  FutureEither<List<AppNotification>> list() =>
      _api.get<List<AppNotification>>(
        '/notifications',
        parse: (data) {
          final map = data is Map ? data.cast<String, dynamic>() : const <String, dynamic>{};
          final items = map['items'];
          return [
            if (items is List)
              for (final e in items)
                if (e is Map) AppNotification.fromJson(e.cast<String, dynamic>()),
          ];
        },
      );

  /// `GET /notifications/unread_count` → number of unread notifications.
  FutureEither<int> unreadCount() => _api.get<int>(
        '/notifications/unread_count',
        parse: (data) {
          final map = data is Map ? data : const <String, dynamic>{};
          final n = map['count'];
          if (n is int) return n;
          if (n is num) return n.toInt();
          return int.tryParse('${n ?? 0}') ?? 0;
        },
      );

  /// `PATCH /notifications/:id/read` → mark one notification read.
  FutureEither<void> markRead(String id) => _api.patch<void>(
        '/notifications/$id/read',
        parse: parseVoid,
      );

  /// `POST /notifications/read_all` → mark every notification read.
  FutureEither<void> markAllRead() => _api.post<void>(
        '/notifications/read_all',
        parse: parseVoid,
      );
}
