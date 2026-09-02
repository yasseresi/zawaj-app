import 'package:equatable/equatable.dart';

/// Aggregate RSVP figures for a wedding (screen 8). Mirrors the backend
/// `service.StatsResult` returned by `GET /weddings/:id/stats`:
/// `{ total_guests, status_breakdown{confirmed,pending,declined}, total_people,
/// confirmed_seats }`.
class WeddingStats extends Equatable {
  const WeddingStats({
    this.totalGuests = 0,
    this.confirmed = 0,
    this.pending = 0,
    this.declined = 0,
    this.totalPeople = 0,
    this.confirmedSeats = 0,
  });

  final int totalGuests;
  final int confirmed;
  final int pending;
  final int declined;
  final int totalPeople;
  final int confirmedSeats;

  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}') ?? 0;
  }

  factory WeddingStats.fromJson(dynamic data) {
    final map = data is Map ? data.cast<String, dynamic>() : const <String, dynamic>{};
    final breakdown = map['status_breakdown'];
    final b = breakdown is Map ? breakdown.cast<String, dynamic>() : const <String, dynamic>{};
    return WeddingStats(
      totalGuests: _int(map['total_guests']),
      confirmed: _int(b['confirmed']),
      pending: _int(b['pending']),
      declined: _int(b['declined']),
      totalPeople: _int(map['total_people']),
      confirmedSeats: _int(map['confirmed_seats']),
    );
  }

  @override
  List<Object?> get props =>
      [totalGuests, confirmed, pending, declined, totalPeople, confirmedSeats];
}
