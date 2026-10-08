// Invite links: `zawaj://i/<token>` or `https://zawaj.app/i/<token>`.

/// Server invite tokens are unpadded base32 (A-Z, 2-7); 15 random bytes give
/// 24 characters. A little slack on length tolerates a future change.
final _tokenPattern = RegExp(r'^[A-Z2-7]{16,32}$');

/// Returns [raw] as a canonical invite token (trimmed, upper-cased), or null
/// if it can't be one. Anything else — path separators, encoded characters,
/// wrong alphabet — is rejected before it reaches a URL or the network.
String? normalizeInviteToken(String raw) {
  final token = raw.trim().toUpperCase();
  return _tokenPattern.hasMatch(token) ? token : null;
}

/// Extracts the invite token from a deep link, or null if [uri] isn't one.
String? parseInviteToken(Uri uri) {
  if (uri.scheme == 'zawaj' && uri.host == 'i') {
    return uri.pathSegments.isEmpty
        ? null
        : normalizeInviteToken(uri.pathSegments.first);
  }
  if ((uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host == 'zawaj.app' &&
      uri.pathSegments.length == 2 &&
      uri.pathSegments.first == 'i') {
    return normalizeInviteToken(uri.pathSegments[1]);
  }
  return null;
}
