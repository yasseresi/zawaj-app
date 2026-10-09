/// Algerian phone helpers. The app is Algeria-only, so numbers are stored and
/// shown in national format (`0672859965`); the international form is only
/// built for WhatsApp links.
///
/// Keep the rules in sync with backend/internal/validation/phone.go.
library;

final _pattern = RegExp(r'^(0[5-7][0-9]{8}|0[2-4][0-9]{7})$');
final _separators = RegExp(r'[\s\-.()]');
const _countryPrefixes = ['+213', '00213', '213'];

/// Returns [raw] as a national-format Algerian number, or null if invalid.
/// Separators are stripped and a +213 / 00213 / 213 prefix becomes a leading 0.
String? normalizePhone(String raw) {
  var v = raw.trim().replaceAll(_separators, '');
  for (final prefix in _countryPrefixes) {
    if (v.startsWith(prefix)) {
      v = '0${v.substring(prefix.length)}';
      break;
    }
  }
  return _pattern.hasMatch(v) ? v : null;
}

/// Groups a national number for display: mobile `0672 85 99 65`, fixed
/// `021 23 45 67`. Anything else is returned unchanged.
String formatPhone(String local) {
  final head = switch (local.length) {
    10 => 4,
    9 => 3,
    _ => 0,
  };
  if (head == 0 || !_pattern.hasMatch(local)) return local;
  final tail = local.substring(head);
  return '${local.substring(0, head)} '
      '${tail.substring(0, 2)} ${tail.substring(2, 4)} ${tail.substring(4)}';
}

Uri telUri(String local) => Uri(scheme: 'tel', path: local);

Uri whatsappUri(String local) => Uri.parse('https://wa.me/213${local.substring(1)}');
