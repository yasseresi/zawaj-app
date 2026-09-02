import '../data/models/guest_detail_model.dart';
import '../data/models/guest_model.dart';
import '../data/services/api_client.dart';
import '../utils/typedefs.dart';

/// API surface for a wedding's guest endpoints. Pure transport: returns
/// [FutureEither] of domain objects, no [BuildContext], no session state.
///
/// Backend contract: `GET /weddings/:id/guests` returns `{ items, counts }`
/// under the standard `{data,error}` envelope (unwrapped by [ApiClient]).
class GuestService {
  GuestService._();
  static final GuestService instance = GuestService._();

  final ApiClient _api = ApiClient.instance;

  /// Lists guests for [weddingId]. [status] (`pending|confirmed|declined`) and
  /// [query] are sent only when non-empty so the backend's optional filters
  /// apply.
  FutureEither<GuestListResult> list(
    String weddingId, {
    String? status,
    String? query,
  }) =>
      _api.get<GuestListResult>(
        '/weddings/$weddingId/guests',
        query: {
          if (status != null && status.isNotEmpty) 'status': status,
          if (query != null && query.isNotEmpty) 'q': query,
        },
        parse: GuestListResult.fromJson,
      );

  /// `GET /weddings/:id/guests/:gid` → the guest with its notes and change
  /// history (`{ guest, notes, history }`).
  FutureEither<GuestDetail> get(String weddingId, String guestId) =>
      _api.get<GuestDetail>(
        '/weddings/$weddingId/guests/$guestId',
        parse: GuestDetail.fromJson,
      );

  /// `POST /weddings/:id/guests` → the created guest (201, editor+). Only
  /// non-empty optional fields are sent so the backend's `omitempty` validators
  /// apply. [companions] is sent as-is when provided (0 is valid).
  FutureEither<Guest> create(
    String weddingId, {
    required String fullName,
    String? contact,
    String? relationship,
    String? status,
    int? companions,
    String? tableLabel,
    String? meal,
    String? note,
  }) =>
      _api.post<Guest>(
        '/weddings/$weddingId/guests',
        body: {
          'full_name': fullName,
          if (contact != null && contact.isNotEmpty) 'contact': contact,
          if (relationship != null && relationship.isNotEmpty)
            'relationship': relationship,
          if (status != null && status.isNotEmpty) 'status': status,
          if (companions != null) 'companions': companions,
          if (tableLabel != null && tableLabel.isNotEmpty) 'table_label': tableLabel,
          if (meal != null && meal.isNotEmpty) 'meal': meal,
          if (note != null && note.isNotEmpty) 'note': note,
        },
        parse: (d) => Guest.fromJson((d as Map).cast<String, dynamic>()),
      );

  /// `PATCH /weddings/:id/guests/:gid/status` → the updated guest (200,
  /// editor+). [status] is a wire value (`pending|confirmed|declined`).
  FutureEither<Guest> setStatus(String weddingId, String guestId, String status) =>
      _api.patch<Guest>(
        '/weddings/$weddingId/guests/$guestId/status',
        body: {'status': status},
        parse: (d) => Guest.fromJson((d as Map).cast<String, dynamic>()),
      );

  /// `POST /weddings/:id/guests/:gid/notes` → the created note (201, editor+).
  FutureEither<GuestNote> addNote(String weddingId, String guestId, String body) =>
      _api.post<GuestNote>(
        '/weddings/$weddingId/guests/$guestId/notes',
        body: {'body': body},
        parse: (d) => GuestNote.fromJson((d as Map).cast<String, dynamic>()),
      );

  /// `POST /weddings/:id/reminders` → send reminders to pending guests.
  FutureEither<int> sendReminders(String weddingId) =>
      _api.post<int>(
        '/weddings/$weddingId/reminders',
        parse: (d) {
          if (d is Map && d.containsKey('count')) {
            return (d['count'] as num).toInt();
          }
          return 0;
        },
      );
}
