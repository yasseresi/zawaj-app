import 'package:flutter/foundation.dart';

import '../../../data/models/guest_model.dart';
import '../../../data/repositories/guest_repository.dart';
import '../../../data/repositories/guest_repository_impl.dart';
import '../../../utils/error_handler.dart';
import '../../../utils/phone.dart';

/// Raw values from the edit-guest form.
class GuestFormValues {
  const GuestFormValues({
    required this.fullName,
    required this.contact,
    required this.relationship,
    required this.status,
    required this.companions,
  });

  final String fullName;
  final String contact;
  final String relationship;
  final RsvpStatus status;
  final int companions;
}

/// Edit form state for one guest (editor+). Diffs the form against the
/// original so `PATCH /weddings/:id/guests/:gid` only carries changed fields.
class EditGuestProvider extends ChangeNotifier {
  EditGuestProvider({
    required String weddingId,
    required Guest guest,
    GuestRepository? repository,
  })  : _weddingId = weddingId,
        _original = guest,
        _repository = repository ?? GuestRepositoryImpl();

  final String _weddingId;
  final Guest _original;
  final GuestRepository _repository;

  bool _isSaving = false;
  String? _errorMessage;

  Guest get original => _original;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  /// The saved contact when it isn't a phone number (pre-phone data). It is
  /// kept as-is unless the user replaces it.
  String? get legacyContact =>
      (_original.contact.isEmpty || normalizePhone(_original.contact) != null)
          ? null
          : _original.contact;

  String _contactValue(String raw) {
    if (legacyContact != null && raw == legacyContact) return _original.contact;
    return raw.trim().isEmpty ? '' : (normalizePhone(raw) ?? raw.trim());
  }

  ({
    String? fullName,
    String? contact,
    String? relationship,
    String? status,
    int? companions,
  }) _diff(GuestFormValues v) {
    String? changed(String value, String original) {
      final t = value.trim();
      return t == original ? null : t;
    }

    final contact = _contactValue(v.contact);
    return (
      fullName: changed(v.fullName, _original.fullName),
      contact: contact == _original.contact ? null : contact,
      relationship: changed(v.relationship, _original.relationship),
      status: v.status == _original.status ? null : v.status.wire,
      companions: v.companions == _original.companions ? null : v.companions,
    );
  }

  bool isDirty(GuestFormValues values) {
    final d = _diff(values);
    return [
      d.fullName,
      d.contact,
      d.relationship,
      d.status,
      d.companions,
    ].any((f) => f != null);
  }

  /// Save the changed fields. Returns the updated guest (or the original when
  /// nothing changed); null on failure with [errorMessage] set.
  Future<Guest?> save(GuestFormValues values) async {
    if (!isDirty(values)) return _original;
    final d = _diff(values);
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.update(
      _weddingId,
      _original.id,
      fullName: d.fullName,
      contact: d.contact,
      relationship: d.relationship,
      status: d.status,
      companions: d.companions,
    );
    _isSaving = false;
    return result.match(
      (failure) {
        _errorMessage = AppErrorHandler.userMessage(failure);
        notifyListeners();
        return null;
      },
      (guest) {
        notifyListeners();
        return guest;
      },
    );
  }
}
