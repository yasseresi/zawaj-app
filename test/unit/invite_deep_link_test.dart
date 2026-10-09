import 'package:flutter_test/flutter_test.dart';
import 'package:zawaj_app/src/routing/invite_deep_link.dart';

// Server tokens: 15 random bytes as unpadded base32 (24 chars, A-Z2-7).
const _token = 'MFRGGZDFMZTWQ2LKNNWG23TP';

void main() {
  test('extracts token from the custom scheme', () {
    expect(parseInviteToken(Uri.parse('zawaj://i/$_token')), _token);
  });

  test('extracts token from the HTTPS share URL', () {
    expect(parseInviteToken(Uri.parse('https://zawaj.app/i/$_token')), _token);
  });

  test('rejects unrelated URLs and malformed invite paths', () {
    expect(
        parseInviteToken(Uri.parse('https://example.com/i/$_token')), isNull);
    expect(parseInviteToken(Uri.parse('zawaj://i/')), isNull);
    expect(parseInviteToken(Uri.parse('zawaj://other/$_token')), isNull);
  });

  group('normalizeInviteToken', () {
    test('accepts the server format, trimming and upper-casing', () {
      expect(normalizeInviteToken(_token), _token);
      expect(normalizeInviteToken(' ${_token.toLowerCase()} '), _token);
    });

    test('rejects anything that is not a server token', () {
      for (final bad in [
        '',
        'ABC123', // too short
        '${_token}0', // '0' and '1' aren't base32
        '../weddings/x',
        'MFRGGZDF/ZTWQ2LKNNWG23TP',
        'MFRGGZDF%2FZTWQ2LKNNWG23T',
        _token * 2, // too long
      ]) {
        expect(normalizeInviteToken(bad), isNull, reason: bad);
      }
    });
  });
}
