import 'package:flutter_test/flutter_test.dart';
import 'package:zawaj_app/src/data/models/user_model.dart';

void main() {
  group('AppUser.fromJson', () {
    test('parses phone and treats a missing phone as null', () {
      final withPhone = AppUser.fromJson(const {
        'id': 'a', 'username': 'u', 'display_name': 'U', 'phone': '0672859965',
      });
      expect(withPhone.phone, '0672859965');
      expect(withPhone.toJson()['phone'], '0672859965');

      final without = AppUser.fromJson(const {'id': 'a', 'username': 'u'});
      expect(without.phone, isNull);
      expect(without.toJson().containsKey('phone'), isFalse);
    });

    test('phone participates in equality', () {
      const a = AppUser(id: '1', username: 'u', displayName: 'U', phone: '0672859965');
      const b = AppUser(id: '1', username: 'u', displayName: 'U');
      expect(a == b, isFalse);
    });

    test('parses the minimal login/me shape and defaults preferences', () {
      final u = AppUser.fromJson(const {
        'id': 'abc',
        'username': 'leila',
        'display_name': 'Leila',
      });
      expect(u.id, 'abc');
      expect(u.username, 'leila');
      expect(u.displayName, 'Leila');
      expect(u.email, isNull);
      expect(u.notifPush, isTrue); // default when absent
      expect(u.darkMode, isFalse);
      expect(u.isPremium, isFalse);
    });

    test('parses the full settings shape including bools as ints/strings', () {
      final u = AppUser.fromJson(const {
        'id': 'x',
        'username': 'omar',
        'display_name': 'Omar',
        'email': 'omar@example.com',
        'dark_mode': true,
        'notif_push': 0,
        'notif_email': 'true',
        'notif_rsvp': 1,
        'is_premium': true,
      });
      expect(u.email, 'omar@example.com');
      expect(u.darkMode, isTrue);
      expect(u.notifPush, isFalse); // 0 -> false
      expect(u.notifEmail, isTrue); // "true" -> true
      expect(u.notifRsvp, isTrue); // 1 -> true
      expect(u.isPremium, isTrue);
    });

    test('falls back displayName to username when missing', () {
      final u = AppUser.fromJson(const {'id': '1', 'username': 'sara'});
      expect(u.displayName, 'sara');
    });
  });

  group('AuthResult.fromJson', () {
    test('captures user, tokens and one-time recovery code', () {
      final r = AuthResult.fromJson(const {
        'user': {'id': '1', 'username': 'sara', 'display_name': 'Sara'},
        'access': 'a.b.c',
        'refresh': 'd.e.f',
        'recovery_code': 'RESQ-1234',
      });
      expect(r.user.username, 'sara');
      expect(r.access, 'a.b.c');
      expect(r.refresh, 'd.e.f');
      expect(r.recoveryCode, 'RESQ-1234');
    });

    test('recovery code is null on login (absent)', () {
      final r = AuthResult.fromJson(const {
        'user': {'id': '1', 'username': 'sara', 'display_name': 'Sara'},
        'access': 'a',
        'refresh': 'b',
      });
      expect(r.recoveryCode, isNull);
    });
  });
}
