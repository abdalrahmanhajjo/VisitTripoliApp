/// Client-side checks aligned with backend `username.js`.
class UsernameValidator {
  static const _reserved = <String>{
    'admin',
    'administrator',
    'support',
    'help',
    'null',
    'undefined',
    'system',
    'tripoli',
    'official',
    'visit',
    'visittripoli',
    'moderator',
    'mod',
    'staff',
  };

  /// Returns `null` if valid, otherwise an error message.
  static String? validate(String? raw) {
    final n = normalize(raw);
    if (n == null || n.isEmpty) return 'Username is required';
    if (n.length < 3 || n.length > 20) {
      return 'Username must be 3–20 characters';
    }
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(n)) {
      return 'Username can only use lowercase letters, numbers, and underscores';
    }
    if (n.startsWith('_') || n.endsWith('_')) {
      return 'Username cannot start or end with an underscore';
    }
    if (_reserved.contains(n)) return 'This username is reserved';
    return null;
  }

  /// Normalized lowercase username for API (no leading `@`).
  static String? normalize(String? raw) {
    if (raw == null) return null;
    var s = raw.trim().replaceFirst(RegExp(r'^@+'), '').toLowerCase();
    if (s.isEmpty) return null;
    return s;
  }
}
