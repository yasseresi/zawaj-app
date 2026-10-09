import 'package:flutter/foundation.dart';

import '../../../data/models/pending_invite_model.dart';
import '../../../data/repositories/invite_repository.dart';
import '../../../data/repositories/invite_repository_impl.dart';
import '../../../shared/enums/app_status.dart';
import '../../../utils/typedefs.dart';
import '../../../utils/error_handler.dart';

export '../../../data/models/pending_invite_model.dart' show PendingInvite;

class PendingInvitesProvider extends ChangeNotifier {
  PendingInvitesProvider({
    InviteRepository? repository,
    List<PendingInvite>? initialInvites,
  })  : _repository = repository ?? InviteRepositoryImpl(),
        _invites = initialInvites ?? const [];

  final InviteRepository _repository;

  AppStatus _status = AppStatus.initial;
  List<PendingInvite> _invites;
  String? _actionLoadingId;
  String? _errorMessage;

  AppStatus get status => _status;
  List<PendingInvite> get invites => _invites;
  String? get actionLoadingId => _actionLoadingId;
  String? get errorMessage => _errorMessage;

  bool get isEmpty => _status.isSuccess && _invites.isEmpty;
  bool get isLoading => _status.isLoading;

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
      (invites) {
        _invites = invites;
        _status = AppStatus.success;
        notifyListeners();
      },
    );
  }

  Future<bool> acceptInvite(String id) => _resolve(id, _repository.accept(id));

  Future<bool> declineInvite(String id) => _resolve(id, _repository.decline(id));

  /// Runs an accept/decline call, removing the invite from the list on success
  /// and surfacing the failure message otherwise. Returns whether it succeeded.
  Future<bool> _resolve(String id, FutureEither<void> action) async {
    _actionLoadingId = id;
    _errorMessage = null;
    notifyListeners();

    final result = await action;
    return result.match(
      (failure) {
        _errorMessage = AppErrorHandler.userMessage(failure);
        _actionLoadingId = null;
        notifyListeners();
        return false;
      },
      (_) {
        _invites = _invites.where((invite) => invite.id != id).toList();
        _actionLoadingId = null;
        notifyListeners();
        return true;
      },
    );
  }

  void setError(String message) {
    _status = AppStatus.failure;
    _errorMessage = message;
    notifyListeners();
  }
}
