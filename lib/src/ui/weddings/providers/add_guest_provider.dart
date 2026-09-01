import 'package:flutter/foundation.dart';

import '../../../data/models/guest_model.dart';
import '../../../data/repositories/guest_repository.dart';
import '../../../data/repositories/guest_repository_impl.dart';
import '../../../shared/enums/app_status.dart';

/// Form state container for adding a guest to a wedding. Normalizes blank
/// optionals to null so the backend's `omitempty` validators apply, and exposes
/// [status]/[errorMessage]/[created] for the view to render.
class AddGuestProvider extends ChangeNotifier {
  AddGuestProvider({required String weddingId, GuestRepository? repository})
      : _weddingId = weddingId,
        _repository = repository ?? GuestRepositoryImpl();

  final String _weddingId;
  final GuestRepository _repository;

  AppStatus _status = AppStatus.initial;
  String? _errorMessage;
  Guest? _created;

  AppStatus get status => _status;
  bool get isLoading => _status.isLoading;
  String? get errorMessage => _errorMessage;
  Guest? get created => _created;

  /// Create the guest. [fullName] is required; blank optionals are dropped.
  /// Returns true on success (view pops + reloads the list); false on failure
  /// (view shows [errorMessage]).
  Future<bool> submit({
    required String fullName,
    String? contact,
    RsvpStatus? status,
    int? companions,
    String? note,
  }) async {
    _status = AppStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.create(
      _weddingId,
      fullName: fullName.trim(),
      contact: _blankToNull(contact),
      status: status?.wire,
      companions: companions,
      note: _blankToNull(note),
    );

    return result.match(
      (failure) {
        _status = AppStatus.failure;
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (guest) {
        _created = guest;
        _status = AppStatus.success;
        notifyListeners();
        return true;
      },
    );
  }

  static String? _blankToNull(String? v) {
    if (v == null) return null;
    final trimmed = v.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
