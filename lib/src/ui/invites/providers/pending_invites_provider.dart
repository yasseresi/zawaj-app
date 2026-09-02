import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/enums/app_status.dart';

class PendingInvite extends Equatable {
  const PendingInvite({
    required this.id,
    required this.event,
    required this.sender,
    required this.date,
    this.initial,
  });

  final String id;
  final String event;
  final String sender;
  final String date;
  final String? initial;

  String get avatarInitial {
    if (initial != null && initial!.isNotEmpty) return initial!;
    final trimmed = sender.trim();
    return trimmed.isEmpty ? '' : trimmed.substring(0, 1);
  }

  @override
  List<Object?> get props => [id, event, sender, date, initial];
}

class PendingInvitesProvider extends ChangeNotifier {
  PendingInvitesProvider({
    List<PendingInvite>? initialInvites,
  }) : _invites = initialInvites ?? const [];

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

    try {
      if (_invites.isEmpty) {
        _invites = _defaultInvites();
      }
      _status = AppStatus.success;
    } catch (e) {
      _status = AppStatus.failure;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<bool> acceptInvite(String id) async {
    _actionLoadingId = id;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 300));

    _invites = _invites.where((invite) => invite.id != id).toList();
    _actionLoadingId = null;
    notifyListeners();
    return true;
  }

  Future<bool> declineInvite(String id) async {
    _actionLoadingId = id;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 300));

    _invites = _invites.where((invite) => invite.id != id).toList();
    _actionLoadingId = null;
    notifyListeners();
    return true;
  }

  void setInvites(List<PendingInvite> invites) {
    _invites = invites;
    _status = AppStatus.success;
    _errorMessage = null;
    notifyListeners();
  }

  void setError(String message) {
    _status = AppStatus.failure;
    _errorMessage = message;
    notifyListeners();
  }

  static List<PendingInvite> _defaultInvites() {
    return const [
      PendingInvite(
        id: '1',
        event: 'حفل زفاف ليلى وعمر',
        sender: 'سارة المنصور',
        date: 'منذ يومين',
        initial: 'س',
      ),
      PendingInvite(
        id: '2',
        event: 'خطوبة ريم',
        sender: 'هند الزهراني',
        date: 'منذ 4 أيام',
        initial: 'هـ',
      ),
      PendingInvite(
        id: '3',
        event: 'حنّاء العروس',
        sender: 'فاطمة الخالدي',
        date: 'منذ أسبوع',
        initial: 'ف',
      ),
    ];
  }
}
