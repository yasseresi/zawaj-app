import 'package:flutter/foundation.dart';

import '../../../data/models/wedding_model.dart';
import '../../../data/repositories/wedding_repository.dart';
import '../../../data/repositories/wedding_repository_impl.dart';
import '../../../shared/enums/app_status.dart';

/// Holds the "my weddings" list state for the home screen. Screens bind via
/// `context.watch` and render off [status] (loading → skeleton, success+empty →
/// empty state, failure → error widget, success → list).
class WeddingsProvider extends ChangeNotifier {
  WeddingsProvider({WeddingRepository? repository})
      : _repository = repository ?? WeddingRepositoryImpl();

  final WeddingRepository _repository;

  AppStatus _status = AppStatus.initial;
  List<Wedding> _weddings = const [];
  String? _errorMessage;

  AppStatus get status => _status;
  List<Wedding> get weddings => _weddings;
  String? get errorMessage => _errorMessage;

  /// True only once a load has succeeded with no weddings — distinguishes the
  /// genuine empty state from the initial/loading states.
  bool get isEmpty => _status.isSuccess && _weddings.isEmpty;

  /// Fetch the caller's weddings. Idempotent; safe to call for pull-to-refresh.
  Future<void> load() async {
    _status = AppStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.myWeddings();
    result.match(
      (failure) {
        _status = AppStatus.failure;
        _errorMessage = failure.message;
        notifyListeners();
      },
      (weddings) {
        _weddings = weddings;
        _status = AppStatus.success;
        notifyListeners();
      },
    );
  }
}
