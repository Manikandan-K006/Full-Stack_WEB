import 'package:intl/intl.dart';

class Formatters {
  static final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  static final _currencyExact = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  static String currency(num value, {bool exact = false}) =>
      exact ? _currencyExact.format(value) : _currency.format(value);

  static String number(num value) => NumberFormat.decimalPattern('en_IN').format(value);

  static String percent(double value) => '${value.toStringAsFixed(1)}%';

  static String dateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  static String date(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  static String relativeTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM yyyy').format(dt);
  }

  static String titleCase(String input) {
    if (input.isEmpty) return input;
    return input
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  static String enumLabel(String input) {
    return titleCase(input.replaceAll('_', ' '));
  }
}