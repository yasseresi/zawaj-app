import 'package:flutter/foundation.dart';

import '../../../data/models/app_notification_model.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/notification_repository_impl.dart';
import '../../../shared/enums/app_status.dart';

export '../../../data/models/app_notification_model.dart' show AppNotification;

/// Drives the notifications feed (list + read state). Mirrors
/// `PendingInvitesProvider`: a plain [ChangeNotifier] over a repository seam.
class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider({
    NotificationRepository? repository,
    List<AppNotification>? initialItems,
  })  : _repository = repository ?? NotificationRepositoryImpl(),
        _items = initialItems ?? const [];

  final NotificationRepository _repository;

  AppStatus _status = AppStatus.initial;
  List<AppNotification> _items;
  String? _errorMessage;

  AppStatus get status => _status;
  List<AppNotification> get items => _items;
  String? get errorMessage => _errorMessage;

  bool get isEmpty => _status.isSuccess && _items.isEmpty;
  bool get isLoading => _status.isLoading;
  int get unreadCount => _items.where((n) => !n.isRead).length;

  Future<void> load() async {
    _status = AppStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.list();
    result.match(
      (failure) {
        _status = AppStatus.failure;
        _errorMessage = failure.message;
        notifyListeners();
      },
      (items) {
        _items = items;
        _status = AppStatus.success;
        notifyListeners();
      },
    );
  }

  /// Marks one notification read, updating it in place on success. Best-effort:
  /// a failure leaves the item unread and is silently ignored (the feed still
  /// works; the count self-corrects on the next reload).
  Future<void> markRead(String id) async {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx < 0 || _items[idx].isRead) return;

    final result = await _repository.markRead(id);
    result.match(
      (_) {},
      (_) {
        _items = [..._items];
        _items[idx] = _items[idx].copyWith(readAt: DateTime.now());
        notifyListeners();
      },
    );
  }

  Future<void> markAllRead() async {
    if (unreadCount == 0) return;
    final now = DateTime.now();
    final result = await _repository.markAllRead();
    result.match(
      (_) {},
      (_) {
        _items = [
          for (final n in _items) n.isRead ? n : n.copyWith(readAt: now),
        ];
        notifyListeners();
      },
    );
  }
}
