import 'package:flutter_test/flutter_test.dart';
import 'package:zawaj_app/src/utils/phone.dart';

// Keep these cases in sync with backend/internal/validation/phone_test.go.
void main() {
  group('normalizePhone', () {
    const valid = {
      '0672859965': '0672859965',
      '0551234567': '0551234567',
      '0771234567': '0771234567',
      '021234567': '021234567',
      '031234567': '031234567',
      '041234567': '041234567',
      '0672 85 99 65': '0672859965',
      '0672-85-99-65': '0672859965',
      '(0672) 85.99.65': '0672859965',
      '+213672859965': '0672859965',
      '+213 672 85 99 65': '0672859965',
      '00213672859965': '0672859965',
      '213672859965': '0672859965',
      '+21321234567': '021234567',
    };
    for (final entry in valid.entries) {
      test('accepts "${entry.key}" as ${entry.value}', () {
        expect(normalizePhone(entry.key), entry.value);
      });
    }

    const invalid = [
      '', '   ', '123', '0551', '0812345678', '0112345678', '06728599651',
      '067285996', '02123456', '0212345678', '+33612345678', 'abc0672859965',
    ];
    for (final input in invalid) {
      test('rejects "$input"', () => expect(normalizePhone(input), isNull));
    }
  });

  group('formatPhone', () {
    test('groups a mobile number as 4-2-2-2', () {
      expect(formatPhone('0672859965'), '0672 85 99 65');
    });

    test('groups a fixed-line number as 3-2-2-2', () {
      expect(formatPhone('021234567'), '021 23 45 67');
    });

    test('returns unrecognised input unchanged', () {
      expect(formatPhone('ali@x.dz'), 'ali@x.dz');
    });
  });

  group('links', () {
    test('tel uses the national number', () {
      expect(telUri('0672859965').toString(), 'tel:0672859965');
    });

    test('WhatsApp uses the international number without the leading 0', () {
      expect(whatsappUri('0672859965').toString(), 'https://wa.me/213672859965');
    });
  });
}
