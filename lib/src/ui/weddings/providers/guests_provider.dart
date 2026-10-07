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

  /// The wedding-wide counts once any load has succeeded, else null. Unlike
  /// [counts] gated on [status], it survives later reloads (tab switch,
  /// search, pull-to-refresh) and their failures, so totals shown outside the
  /// list don't flash back to a placeholder.
  GuestCounts? get knownCounts => _hasLoaded ? _counts : null;
  bool _hasLoaded = false;
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
        _hasLoaded = true;
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

  /// Delete [guestId] (editor+). On success removes it from the current page and
  /// decrements the wedding-wide counts locally so the UI updates instantly —
  /// no refetch. Returns the failure message, or null on success (so the caller
  /// can toast the outcome).
  Future<String?> delete(String guestId) async {
    final matches = _guests.where((g) => g.id == guestId);
    final RsvpStatus? status = matches.isEmpty ? null : matches.first.status;
    final result = await _repository.delete(_weddingId, guestId);
    return result.match(
      (failure) => failure.message,
      (_) {
        _guests = _guests.where((g) => g.id != guestId).toList(growable: false);
        if (status != null) _counts = _countsWithout(status);
        notifyListeners();
        return null;
      },
    );
  }

  /// Apply an edited guest (from the edit screen) without refetching: swap the
  /// row, move the wedding-wide counts if its status changed, and drop it from
  /// the page when it no longer matches the active filter tab. No-op for
  /// guests not on the current page.
  void replace(Guest updated) {
    final index = _guests.indexWhere((g) => g.id == updated.id);
    if (index < 0) return;
    final previous = _guests[index].status;
    if (previous != updated.status) {
      final moved = _countsWithout(previous);
      _counts = _countsWith(moved, updated.status);
    }
    final stillMatches =
        _filter == GuestFilter.all || _filter.wire == updated.status.name;
    _guests = [
      for (final (i, g) in _guests.indexed)
        if (i != index)
          g
        else if (stillMatches)
          updated,
    ];
    notifyListeners();
  }

  /// [counts] with one more guest of [status] (and the `all` total).
  static GuestCounts _countsWith(GuestCounts counts, RsvpStatus status) {
    final all = counts.all + 1;
    return switch (status) {
      RsvpStatus.confirmed =>
        counts.copyWith(all: all, confirmed: counts.confirmed + 1),
      RsvpStatus.pending =>
        counts.copyWith(all: all, pending: counts.pending + 1),
      RsvpStatus.declined =>
        counts.copyWith(all: all, declined: counts.declined + 1),
    };
  }

  /// The counts with one guest of [status] removed (and the `all` total).
  GuestCounts _countsWithout(RsvpStatus status) {
    switch (status) {
      case RsvpStatus.confirmed:
        return _counts.copyWith(all: _counts.all - 1, confirmed: _counts.confirmed - 1);
      case RsvpStatus.pending:
        return _counts.copyWith(all: _counts.all - 1, pending: _counts.pending - 1);
      case RsvpStatus.declined:
        return _counts.copyWith(all: _counts.all - 1, declined: _counts.declined - 1);
    }
  }

  /// Set the search term and refetch. Callers should debounce keystrokes.
  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed == _searchQuery) return;
    _searchQuery = trimmed;
    await load();
  }
}
