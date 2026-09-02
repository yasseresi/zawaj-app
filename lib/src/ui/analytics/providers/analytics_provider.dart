import 'package:flutter/foundation.dart';

import '../../../data/models/guest_model.dart';
import '../../../data/repositories/guest_repository.dart';
import '../../../data/repositories/guest_repository_impl.dart';
import '../../../shared/enums/app_status.dart';

enum BroadcastState {
  idle,
  confirm,
  sending,
  success,
  error,
}

class AnalyticsProvider extends ChangeNotifier {
  AnalyticsProvider({
    required String weddingId,
    GuestRepository? repository,
  })  : _weddingId = weddingId,
        _repository = repository ?? GuestRepositoryImpl();

  final String _weddingId;
  final GuestRepository _repository;

  AppStatus _status = AppStatus.initial;
  GuestCounts _counts = const GuestCounts();
  String? _errorMessage;
  BroadcastState _broadcastState = BroadcastState.idle;
  int _lastSentCount = 0;
  final List<int> _timelineData = const [12, 28, 45, 68, 92, 118, 142];

  String get weddingId => _weddingId;
  AppStatus get status => _status;
  GuestCounts get counts => _counts;
  String? get errorMessage => _errorMessage;
  BroadcastState get broadcastState => _broadcastState;
  int get lastSentCount => _lastSentCount;
  List<int> get timelineData => _timelineData;

  int get totalGuests => _counts.all;
  int get confirmedCount => _counts.confirmed;
  int get declinedCount => _counts.declined;
  int get pendingCount => _counts.pending;

  bool get isEmpty => _status == AppStatus.success && _counts.all == 0;
  bool get isLoading => _status == AppStatus.loading;

  Future<void> load() async {
    _status = AppStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.list(_weddingId);
    result.match(
      (failure) {
        _status = AppStatus.failure;
        _errorMessage = failure.message;
        notifyListeners();
      },
      (data) {
        _counts = data.counts;
        _status = AppStatus.success;
        notifyListeners();
      },
    );
  }

  void openBroadcastConfirm() {
    _broadcastState = BroadcastState.confirm;
    notifyListeners();
  }

  void cancelBroadcast() {
    _broadcastState = BroadcastState.idle;
    notifyListeners();
  }

  Future<void> sendReminders() async {
    _broadcastState = BroadcastState.sending;
    notifyListeners();

    final result = await _repository.sendReminders(_weddingId);
    result.match(
      (failure) {
        _broadcastState = BroadcastState.error;
        _errorMessage = failure.message;
        notifyListeners();
      },
      (count) {
        _lastSentCount = count > 0 ? count : _counts.pending;
        _broadcastState = BroadcastState.success;
        notifyListeners();
      },
    );
  }

  void dismissBroadcastResult() {
    _broadcastState = BroadcastState.idle;
    notifyListeners();
  }
}
