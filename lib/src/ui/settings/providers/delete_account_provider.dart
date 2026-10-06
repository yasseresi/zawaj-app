import 'package:flutter/foundation.dart';

import '../../../data/models/wedding_model.dart';
import '../../../data/repositories/wedding_repository.dart';
import '../../../data/repositories/wedding_repository_impl.dart';
import '../../../shared/enums/app_status.dart';
import '../../../utils/error_handler.dart';
import '../../../utils/failure.dart';
import '../../auth/providers/session_provider.dart';

/// An owned wedding that deletion would wipe, with how many other people
/// would lose it.
class OwnedWedding {
  const OwnedWedding({required this.wedding, required this.collaborators});
  final Wedding wedding;
  final int collaborators;
}

enum DeleteOutcome { deleted, wrongPassword, locked, failed }

/// Delete-account flow: [load] builds the impact summary (owned weddings and
/// their collaborators, shared-wedding count); [submit] performs the
/// password-confirmed delete through the session.
class DeleteAccountProvider extends ChangeNotifier {
  DeleteAccountProvider({
    WeddingRepository? weddingRepository,
    SessionProvider? session,
  })  : _weddings = weddingRepository ?? WeddingRepositoryImpl(),
        _session = session ?? sessionProvider;

  final WeddingRepository _weddings;
  final SessionProvider _session;

  AppStatus _status = AppStatus.initial;
  List<OwnedWedding> _owned = const [];
  int _sharedCount = 0;
  bool _isSubmitting = false;
  String? _errorMessage;

  AppStatus get status => _status;
  List<OwnedWedding> get owned => _owned;
  int get sharedCount => _sharedCount;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _status = AppStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _weddings.myWeddings();
    await result.match(
      (failure) async {
        _status = AppStatus.failure;
        _errorMessage = failure.message;
      },
      (weddings) async {
        final mine = weddings.where((w) => w.role.isOwner).toList();
        final counts = await Future.wait(mine.map((w) async {
          final members = await _weddings.members(w.id);
          // Unknown on failure: assume others may be affected (show it).
          return members.match((_) => 1, (m) => m.length - 1);
        }));
        _owned = [
          for (final (i, w) in mine.indexed)
            OwnedWedding(wedding: w, collaborators: counts[i])
        ];
        _sharedCount = weddings.length - mine.length;
        _status = AppStatus.success;
      },
    );
    notifyListeners();
  }

  Future<DeleteOutcome> submit(String password) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final failure = await _session.deleteAccount(password);
    _isSubmitting = false;
    final outcome = switch (failure) {
      null => DeleteOutcome.deleted,
      AuthFailure() => DeleteOutcome.wrongPassword,
      _ when failure is LockedFailure || failure.code == 'locked' =>
        DeleteOutcome.locked,
      _ => DeleteOutcome.failed,
    };
    if (outcome == DeleteOutcome.failed) {
      _errorMessage = AppErrorHandler.userMessage(failure!);
    }
    notifyListeners();
    return outcome;
  }
}
