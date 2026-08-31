import 'package:flutter_test/flutter_test.dart';
import 'package:zawaj_app/src/data/models/wedding_model.dart';

void main() {
  group('Wedding.fromJson', () {
    test('parses the full list-item shape from GET /weddings', () {
      final w = Wedding.fromJson(const {
        'id': 'w1',
        'name': 'Leila & Karim',
        'event_date': '2026-09-20',
        'description': 'Garden ceremony',
        'owner_id': 'u1',
        'my_role': 'owner',
        'guest_count': 42,
        'created_at': '2026-08-01T10:00:00Z',
      });

      expect(w.id, 'w1');
      expect(w.name, 'Leila & Karim');
      expect(w.eventDate, DateTime(2026, 9, 20));
      expect(w.description, 'Garden ceremony');
      expect(w.ownerId, 'u1');
      expect(w.role, WeddingRole.owner);
      expect(w.guestCount, 42);
    });

    test('tolerates a missing/null event_date and description', () {
      final w = Wedding.fromJson(const {
        'id': 'w2',
        'name': 'Untitled',
        'owner_id': 'u1',
        'my_role': 'viewer',
      });

      expect(w.eventDate, isNull);
      expect(w.description, '');
      expect(w.role, WeddingRole.viewer);
      expect(w.guestCount, 0);
    });

    test('coerces a string guest_count and unknown role', () {
      final w = Wedding.fromJson(const {
        'id': 'w3',
        'name': 'X',
        'owner_id': 'u1',
        'my_role': 'bogus',
        'guest_count': '7',
      });

      expect(w.guestCount, 7);
      expect(w.role, WeddingRole.viewer); // safest default
    });
  });
}
