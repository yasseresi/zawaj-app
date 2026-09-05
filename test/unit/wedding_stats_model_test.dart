import 'package:flutter_test/flutter_test.dart';
import 'package:zawaj_app/src/data/models/wedding_stats_model.dart';

void main() {
  test('parses the backend by_status analytics response', () {
    final stats = WeddingStats.fromJson(const {
      'total_guests': 3,
      'by_status': {'confirmed': 1, 'pending': 1, 'declined': 1},
      'total_people': 5,
      'confirmed_seats': 2,
    });

    expect(stats.totalGuests, 3);
    expect(stats.confirmed, 1);
    expect(stats.pending, 1);
    expect(stats.declined, 1);
    expect(stats.totalPeople, 5);
    expect(stats.confirmedSeats, 2);
  });
}
