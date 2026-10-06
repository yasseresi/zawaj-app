import 'package:flutter/foundation.dart';

import '../../../data/models/wedding_model.dart';
import '../../../data/repositories/wedding_repository.dart';
import '../../../data/repositories/wedding_repository_impl.dart';
import '../../../extensions/extensions.dart';
import '../../../utils/error_handler.dart';

/// Edit form state for one wedding (owner). Diffs the form against the
/// original so `PATCH /weddings/:id` only carries changed fields.
class EditWeddingProvider extends ChangeNotifier {
  EditWeddingProvider({required Wedding wedding, WeddingRepository? repository})
      : _original = wedding,
        _repository = repository ?? WeddingRepositoryImpl();

  final Wedding _original;
  final WeddingRepository _repository;

  bool _isSaving = false;
  String? _errorMessage;

  Wedding get original => _original;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  ({String? name, String? eventDate, String? description}) _diff(
      String name, DateTime? date, String description) {
    final n = name.trim();
    final d = description.trim();
    final day = date?.toIso8601DateOnly;
    return (
      name: n == _original.name ? null : n,
      eventDate: day == _original.eventDate?.toIso8601DateOnly ? null : day,
      description: d == _original.description ? null : d,
    );
  }

  bool isDirty(
      {required String name,
      required DateTime? date,
      required String description}) {
    final diff = _diff(name, date, description);
    return diff.name != null ||
        diff.eventDate != null ||
        diff.description != null;
  }

  /// Save the changed fields. Returns the server's (bare) wedding — merge it
  /// with `Wedding.withEdits` — or the original when nothing changed; null on
  /// failure with [errorMessage] set.
  Future<Wedding?> save(
      {required String name,
      required DateTime? date,
      required String description}) async {
    final diff = _diff(name, date, description);
    if (diff.name == null &&
        diff.eventDate == null &&
        diff.description == null) {
      return _original;
    }
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.update(_original.id,
        name: diff.name,
        eventDate: diff.eventDate,
        description: diff.description);
    _isSaving = false;
    return result.match(
      (failure) {
        _errorMessage = AppErrorHandler.userMessage(failure);
        notifyListeners();
        return null;
      },
      (wedding) {
        notifyListeners();
        return wedding;
      },
    );
  }
}
