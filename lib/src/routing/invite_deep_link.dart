String? parseInviteToken(Uri uri) {
  if (uri.scheme == 'zawaj' && uri.host == 'i') {
    return _nonEmpty(uri.pathSegments.isEmpty ? null : uri.pathSegments.first);
  }
  if ((uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host == 'zawaj.app' &&
      uri.pathSegments.length == 2 &&
      uri.pathSegments.first == 'i') {
    return _nonEmpty(uri.pathSegments[1]);
  }
  return null;
}

String? _nonEmpty(String? value) =>
    value == null || value.isEmpty ? null : value;
