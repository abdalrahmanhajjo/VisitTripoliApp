/// Heuristic for user-facing copy when the device cannot reach the API.
bool isLikelyNetworkError(Object e) {
  final s = e.toString().toLowerCase();
  return s.contains('socket') ||
      s.contains('timeout') ||
      s.contains('connection') ||
      s.contains('network') ||
      s.contains('failed host') ||
      s.contains('failed to fetch') ||
      s.contains('clientexception') ||
      s.contains('handshake');
}
