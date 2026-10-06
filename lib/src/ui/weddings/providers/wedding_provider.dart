import 'package:flutter/foundation.dart';

import '../../../data/models/wedding_model.dart';
import '../../../data/repositories/wedding_repository.dart';
import '../../../data/repositories/wedding_repository_impl.dart';
import '../../../shared/enums/app_status.dart';
import '../../../utils/failure.dart';

/// One wedding for the wedding screen. Renders [initial] (navigation `extra`)
/// instantly, then [load] fetches `GET /weddings/:id` for the current role —
/// or cold-loads it for deep links and notification taps. A 404 (deleted or
/// access revoked) sets [isNotFound].
class WeddingProvider extends ChangeNotifier {
  WeddingProvider({
    required String weddingId,
    Wedding? initial,
    WeddingRepository? repository,
  })  : _weddingId = weddingId,
        _wedding = initial,
        _status = initial == null ? AppStatus.initial : AppStatus.success,
        _repository = repository ?? WeddingRepositoryImpl();

  final String _weddingId;
  final WeddingRepository _repository;

  Wedding? _wedding;
  AppStatus _status;
  bool _isNotFound = false;
  String? _errorMessage;

  String get weddingId => _weddingId;
  Wedding? get wedding => _wedding;
  AppStatus get status => _status;
  bool get isNotFound => _isNotFound;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    if (_wedding == null) {
      _status = AppStatus.loading;
      _errorMessage = null;
      notifyListeners();
    }
    final result = await _repository.get(_weddingId);
    result.match(
      (failure) {
        if (failure is NotFoundFailure) {
          _isNotFound = true;
        } else if (_wedding == null) {
          _status = AppStatus.failure;
          _errorMessage = failure.message;
        }
        notifyListeners();
      },
      (fresh) {
        final cached = _wedding;
        _wedding = cached == null
            ? fresh
            : fresh.copyWith(guestCount: cached.guestCount);
        _isNotFound = false;
        _status = AppStatus.success;
        notifyListeners();
      },
    );
  }

  /// Merge a `PATCH /weddings/:id` result (no role / guest count).
  void applyUpdate(Wedding updated) {
    final cached = _wedding;
    if (cached == null) return;
    _wedding = cached.withEdits(updated);
    notifyListeners();
  }
}
