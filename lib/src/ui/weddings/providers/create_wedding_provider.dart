import 'package:flutter/foundation.dart';

import '../../../data/models/wedding_model.dart';
import '../../../data/repositories/wedding_repository.dart';
import '../../../data/repositories/wedding_repository_impl.dart';
import '../../../shared/enums/app_status.dart';

/// Drives the create-wedding form. Holds an [AppStatus] + last error; the screen
/// binds to it, surfaces the error as a toast, and on success pops back so the
/// home list reloads.
class CreateWeddingProvider extends ChangeNotifier {
  CreateWeddingProvider({WeddingRepository? repository})
      : _repository = repository ?? WeddingRepositoryImpl();

  final WeddingRepository _repository;

  AppStatus _status = AppStatus.initial;
  String? _errorMessage;
  Wedding? _created;

  AppStatus get status => _status;
  bool get isLoading => _status.isLoading;
  String? get errorMessage => _errorMessage;
  Wedding? get created => _created;

  /// Submit the form. Empty/blank optional fields are normalized to `null` so
  /// the backend's `omitempty` rules apply. Returns true on success.
  Future<bool> submit({
    required String name,
    String? eventDate,
    String? description,
  }) async {
    _status = AppStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.create(
      name: name.trim(),
      eventDate: _clean(eventDate),
      description: _clean(description),
    );
    return result.match(
      (failure) {
        _status = AppStatus.failure;
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (wedding) {
        _created = wedding;
        _status = AppStatus.success;
        notifyListeners();
        return true;
      },
    );
  }

  static String? _clean(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}
