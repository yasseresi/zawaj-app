import 'package:flutter/foundation.dart';

import '../../../data/models/guest_model.dart';
import '../../../data/repositories/guest_repository.dart';
import '../../../data/repositories/guest_repository_impl.dart';
import '../../../shared/enums/app_status.dart';

/// The four RSVP filter tabs on the guest-list screen. [all] maps to no
/// server-side status filter; the rest map to their [RsvpStatus] wire value.
enum GuestFilter {
  all,
  confirmed,
  pending,
  declined;

  /// The `?status=` value for this tab, or null for [all].
  String? get wire => this == GuestFilter.all ? null : name;
}

/// Holds one wedding's guest-list state: the filtered page of guests, the
/// wedding-wide RSVP tab counts, the active [filter] tab, and the [searchQuery].
/// Filtering and search are server-driven — changing either refetches — while
/// counts stay wedding-wide (the backend ignores the filter when counting).
class GuestsProvider extends ChangeNotifier {
  GuestsProvider({required String weddingId, GuestRepository? repository})
      : _weddingId = weddingId,
        _repository = repository ?? GuestRepositoryImpl();

  final String _weddingId;
  final GuestRepository _repository;

  AppStatus _status = AppStatus.initial;
  List<Guest> _guests = const [];
  GuestCounts _counts = const GuestCounts();
  GuestFilter _filter = GuestFilter.all;
  String _searchQuery = '';
  String? _errorMessage;

  String get weddingId => _weddingId;
  AppStatus get status => _status;
  List<Guest> get guests => _guests;
  GuestCounts get counts => _counts;
  GuestFilter get filter => _filter;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;

  /// True only once a load has succeeded with no guests for the active filter —
  /// distinguishes a genuine empty result from the initial/loading states.
  bool get isEmpty => _status.isSuccess && _guests.isEmpty;

  /// Fetch guests for the active [filter] and [searchQuery]. Idempotent; safe
  /// for pull-to-refresh.
  Future<void> load() async {
    _status = AppStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.list(
      _weddingId,
      status: _filter.wire,
      query: _searchQuery.isEmpty ? null : _searchQuery,
    );
    result.match(
      (failure) {
        _status = AppStatus.failure;
        _errorMessage = failure.message;
        notifyListeners();
      },
      (data) {
        _guests = data.items;
        _counts = data.counts;
        _status = AppStatus.success;
        notifyListeners();
      },
    );
  }

  /// Switch the RSVP tab and refetch. No-op when [next] is already active.
  Future<void> setFilter(GuestFilter next) async {
    if (next == _filter) return;
    _filter = next;
    await load();
  }

  /// Set the search term and refetch. Callers should debounce keystrokes.
  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed == _searchQuery) return;
    _searchQuery = trimmed;
    await load();
  }
}
