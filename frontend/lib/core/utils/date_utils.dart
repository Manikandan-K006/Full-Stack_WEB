class DateUtilsExt {
  static String normalize(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  static DateTime parseIso(String iso) {
    final dt = DateTime.tryParse(iso);
    return dt ?? DateTime.now();
  }

  static bool isOverdue(String? iso) {
    if (iso == null || iso.isEmpty) return false;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return false;
    return dt.isBefore(DateTime.now());
  }

  static int daysBetween(DateTime a, DateTime b) =>
      DateTime(b.year, b.month, b.day).difference(DateTime(a.year, a.month, a.day)).inDays;
}