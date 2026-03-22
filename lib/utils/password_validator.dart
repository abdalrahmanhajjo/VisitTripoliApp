/// Strong password validation matching backend rules.
/// Requirements: min 8 chars, uppercase, lowercase, number, special character.
class PasswordValidator {
  static const _weakPasswords = {
    'password',
    'password1',
    'password123',
    '123456',
    '12345678',
    'qwerty',
    'abc123',
    'monkey',
    'letmein',
    'trustno1',
    'dragon',
    'baseball',
    'iloveyou',
    'master',
    'sunshine',
    'princess',
    'football',
    'admin',
    'welcome',
    'login',
    'passw0rd',
    'tripoli1',
    'tripoli123',
  };

  static final _specialCharsRegex =
      RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>/?~]');

  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Let required validator handle empty
    }
    final p = value.trim();
    if (p.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (p.length > 128) {
      return 'Password must be under 128 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(p)) {
      return 'Must contain an uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(p)) {
      return 'Must contain a lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(p)) {
      return 'Must contain a number';
    }
    if (!_specialCharsRegex.hasMatch(p)) {
      return 'Must contain a special character (!@#\$%^&* etc.)';
    }
    if (_weakPasswords.contains(p.toLowerCase())) {
      return 'This password is too common. Choose a stronger one.';
    }
    if (RegExp(r'(.)\1{3,}').hasMatch(p)) {
      return 'Avoid repeated characters (e.g. aaaa)';
    }
    return null;
  }
}
