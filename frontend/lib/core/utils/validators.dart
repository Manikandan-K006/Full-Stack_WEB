final RegExp _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');
final RegExp _phoneRe = RegExp(r'^\+?[0-9\s\-()]{7,20}$');

class Validators {
  static String? required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailRe.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!value.contains(RegExp(r'[A-Za-z]')) || !value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a letter and a digit';
    }
    return null;
  }

  static String? minLength(String? value, int min, String label) {
    if (value == null || value.trim().length < min) {
      return '$label must be at least $min characters';
    }
    return null;
  }

  static String? maxLength(String? value, int max, String label) {
    if (value != null && value.length > max) {
      return '$label must be at most $max characters';
    }
    return null;
  }

  static String? positiveNumber(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    final n = double.tryParse(value.trim());
    if (n == null || n < 0) return '$label must be a valid non-negative number';
    return null;
  }

  static String? date(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    try {
      DateTime.parse(value.trim());
    } catch (_) {
      return '$label must be a valid date (YYYY-MM-DD)';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone is required';
    if (!_phoneRe.hasMatch(value.trim())) return 'Enter a valid phone number';
    return null;
  }

  static String? url(String? value, String label) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return '$label must be a valid http(s) URL';
    }
    return null;
  }
}