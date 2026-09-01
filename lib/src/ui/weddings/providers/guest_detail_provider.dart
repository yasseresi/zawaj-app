import 'package:flutter/foundation.dart';

import '../../../data/models/guest_detail_model.dart';
import '../../../data/models/guest_model.dart';
import '../../../data/repositories/guest_repository.dart';
import '../../../data/repositories/guest_repository_impl.dart';
import '../../../shared/enums/app_status.dart';

/// Holds one guest's detail state (guest + notes + history) for the detail
/// screen. Screens bind via `context.watch` and render off [status].
class GuestDetailProvider extends ChangeNotifier {
  GuestDetailProvider({
    required String weddingId,
    required String guestId,
    GuestRepository? repository,
  })  : _weddingId = weddingId,
        _guestId = guestId,
        _repository = repository ?? GuestRepositoryImpl();

  final String _weddingId;
  final String _guestId;
  final GuestRepository _repository;

  AppStatus _status = AppStatus.initial;
  GuestDetail? _detail;
  String? _errorMessage;

  AppStatus get status => _status;
  GuestDetail? get detail => _detail;
  String? get errorMessage => _errorMessage;

  /// Fetch the guest with its notes and history. Idempotent; safe for
  /// pull-to-refresh and for reloading after a note/status write.
  Future<void> load() async {
    _status = AppStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.get(_weddingId, _guestId);
    result.match(
      (failure) {
        _status = AppStatus.failure;
        _errorMessage = failure.message;
        notifyListeners();
      },
      (detail) {
        _detail = detail;
        _status = AppStatus.success;
        notifyListeners();
      },
    );
  }

  /// Set the guest's RSVP status (editor+), then reload so the header status and
  /// history timeline reflect the change. Returns true on success; on failure
  /// the detail stays visible and [errorMessage] carries the reason (the view
  /// shows a toast).
  Future<bool> setStatus(RsvpStatus status) async {
    _errorMessage = null;
    final result = await _repository.setStatus(_weddingId, _guestId, status.wire);
    return result.match(
      (failure) async {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (_) async {
        await load();
        return true;
      },
    );
  }

  /// Add a note to the guest (editor+), then reload so the notes thread and
  /// history reflect it. Returns true on success; on failure the detail stays
  /// visible and [errorMessage] carries the reason.
  Future<bool> addNote(String body) async {
    _errorMessage = null;
    final result = await _repository.addNote(_weddingId, _guestId, body.trim());
    return result.match(
      (failure) async {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (_) async {
        await load();
        return true;
      },
    );
  }
}
