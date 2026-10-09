import 'package:flutter/foundation.dart';

import '../../../data/models/wedding_model.dart';
import '../../../data/repositories/wedding_repository.dart';
import '../../../data/repositories/wedding_repository_impl.dart';
import '../../../shared/enums/app_status.dart';
import '../../../services/storage_service.dart';

/// Holds the "my weddings" list state for the home screen. Screens bind via
/// `context.watch` and render off [status] (loading → skeleton, success+empty →
/// empty state, failure → error widget, success → list).
class WeddingsProvider extends ChangeNotifier {
  WeddingsProvider({WeddingRepository? repository})
      : _repository = repository ?? WeddingRepositoryImpl();

  final WeddingRepository _repository;

  AppStatus _status = AppStatus.initial;
  List<Wedding> _weddings = const [];
  String? _selectedWeddingId;
  String? _errorMessage;

  AppStatus get status => _status;
  List<Wedding> get weddings => _weddings;
  String? get selectedWeddingId => _selectedWeddingId;
  String? get errorMessage => _errorMessage;

  /// True only once a load has succeeded with no weddings — distinguishes the
  /// genuine empty state from the initial/loading states.
  bool get isEmpty => _status.isSuccess && _weddings.isEmpty;

  Wedding? weddingById(String id) {
    for (final w in _weddings) {
      if (w.id == id) return w;
    }
    return null;
  }

  /// Fetch the caller's weddings. Idempotent; safe to call for pull-to-refresh.
  /// [silent] re-syncs in the background (e.g. returning from a wedding):
  /// the current list stays on screen, and a failure keeps it as is.
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _status = AppStatus.loading;
      _errorMessage = null;
      notifyListeners();
    }

    final result = await _repository.myWeddings();
    result.match(
      (failure) {
        if (silent && _status.isSuccess) return;
        _status = AppStatus.failure;
        _errorMessage = failure.message;
        notifyListeners();
      },
      (weddings) {
        _weddings = weddings;
        final lastId = StorageService.instance.lastAccessedWeddingId;
        _selectedWeddingId = weddings.any((w) => w.id == lastId)
            ? lastId
            : weddings.isEmpty
                ? null
                : weddings.first.id;
        _status = AppStatus.success;
        notifyListeners();
      },
    );
  }

  Future<void> selectWedding(String id) async {
    if (!_weddings.any((w) => w.id == id) || _selectedWeddingId == id) return;
    _selectedWeddingId = id;
    notifyListeners();
    await StorageService.instance.setLastAccessedWeddingId(id);
  }

  /// Delete a wedding (owner-only, server-enforced). On success the row is
  /// dropped locally so the list — or the empty state, once none remain —
  /// updates without a full reload. Returns whether it succeeded; on failure
  /// [errorMessage] carries the reason and the list is left untouched.
  Future<bool> delete(String id) async {
    final result = await _repository.delete(id);
    return result.match(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        _weddings = _weddings.where((w) => w.id != id).toList();
        notifyListeners();
        return true;
      },
    );
  }

  /// Merge a `PATCH /weddings/:id` result into the cached item. The response
  /// has no role or guest count, so only the editable fields are taken.
  void applyUpdate(Wedding updated) {
    _weddings = [
      for (final w in _weddings) w.id == updated.id ? w.withEdits(updated) : w
    ];
    notifyListeners();
  }
}
