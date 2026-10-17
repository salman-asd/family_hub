import 'package:family_hub/core/utils/bangla_numerals.dart';
import 'package:family_hub/core/utils/money.dart';

/// Localized display formatting for dates, numbers and money.
///
/// Every formatter takes the active [languageCode] ('bn' or 'en') and the
/// [useBanglaDigits] switch, so the UI never hard-codes a format or a digit
/// script.  This is the single formatting edge referenced from the roadmap:
/// "date (e.g. '১৪ অক্টোবর ২০২৬' / '14 October 2026'), month name, weekday,
/// number, and Money, all honoring the locale and the Bangla-digits switch."
///
/// The Bangla month names follow the Gregorian calendar as used in Bangladesh
/// (জানুয়ারি … ডিসেম্বর).  Weekday names follow the working week used in the
/// app (শনিবার first, শুক্রবার last) — Sunday is 1 in [DateTime.weekday].
class AppFormatters {
  const AppFormatters({
    required this.languageCode,
    required this.useBanglaDigits,
  });

  final String languageCode;
  final bool useBanglaDigits;

  bool get _isBangla => languageCode == 'bn';

  // ── Number ──────────────────────────────────────────────────────────────────

  /// Formats an integer with locale grouping: Bangla uses lakh grouping
  /// (১,২৩,৪৫৬), English uses international grouping (123,456).
  String number(int value) {
    final negative = value < 0;
    final digits = _group(value.abs().toString());
    final text = negative ? '-$digits' : digits;
    return _applyDigits(text);
  }

  // ── Money ───────────────────────────────────────────────────────────────────

  /// Formats [Money] with the taka symbol and locale-aware grouping, honoring
  /// the Bangla-digits switch.  Reuses [MoneyFormatter] so money formatting has
  /// exactly one implementation.
  String money(Money value, {bool hideZeroFraction = false}) {
    return MoneyFormatter(
      locale: languageCode,
      hideZeroFraction: hideZeroFraction,
      useBanglaDigits: useBanglaDigits,
    ).format(value);
  }

  // ── Date ────────────────────────────────────────────────────────────────────

  /// '১৪ অক্টোবর ২০২৬' (bn) / '14 October 2026' (en).
  ///
  /// The day and year are never grouped with separators — only [number] adds
  /// lakh/international grouping.
  String fullDate(DateTime date) =>
      '${_applyDigits(date.day.toString())} ${monthName(date.month)} '
      '${_applyDigits(date.year.toString())}';

  /// 'অক্টোবর' (bn) / 'October' (en).
  String monthName(int month) {
    _checkMonth(month);
    return _isBangla ? _monthsBn[month - 1] : _monthsEn[month - 1];
  }

  /// 'শুক্র' (bn short) / 'Fri' (en short).
  String weekdayShort(int weekday) {
    _checkWeekday(weekday);
    return _isBangla
        ? _weekdaysBnShort[weekday - 1]
        : _weekdaysEnShort[weekday - 1];
  }

  /// 'শুক্রবার' (bn) / 'Friday' (en).
  String weekdayName(int weekday) {
    _checkWeekday(weekday);
    return _isBangla ? _weekdaysBn[weekday - 1] : _weekdaysEn[weekday - 1];
  }

  // ── Internal ────────────────────────────────────────────────────────────────

  String _applyDigits(String text) =>
      useBanglaDigits ? toBanglaDigits(text) : text;

  String _group(String digits) {
    if (digits.length <= 3) return digits;
    final tail = digits.substring(digits.length - 3);
    var head = digits.substring(0, digits.length - 3);
    final size = _isBangla ? 2 : 3;
    final parts = <String>[];
    while (head.length > size) {
      parts.insert(0, head.substring(head.length - size));
      head = head.substring(0, head.length - size);
    }
    parts.insert(0, head);
    return '${parts.join(',')},$tail';
  }

  void _checkMonth(int month) {
    if (month < 1 || month > 12) {
      throw RangeError.range(month, 1, 12, 'month');
    }
  }

  void _checkWeekday(int weekday) {
    if (weekday < 1 || weekday > 7) {
      throw RangeError.range(weekday, 1, 7, 'weekday');
    }
  }

  // ── Name tables ─────────────────────────────────────────────────────────────

  static const List<String> _monthsBn = [
    'জানুয়ারি',
    'ফেব্রুয়ারি',
    'মার্চ',
    'এপ্রিল',
    'মে',
    'জুন',
    'জুলাই',
    'আগস্ট',
    'সেপ্টেম্বর',
    'অক্টোবর',
    'নভেম্বর',
    'ডিসেম্বর',
  ];

  static const List<String> _monthsEn = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Indexed by [DateTime.weekday] - 1 (Monday = 0 … Sunday = 6).
  static const List<String> _weekdaysBn = [
    'সোমবার',
    'মঙ্গলবার',
    'বুধবার',
    'বৃহস্পতিবার',
    'শুক্রবার',
    'শনিবার',
    'রবিবার',
  ];

  static const List<String> _weekdaysEn = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _weekdaysBnShort = [
    'সোম',
    'মঙ্গল',
    'বুধ',
    'বৃহঃ',
    'শুক্র',
    'শনি',
    'রবি',
  ];

  static const List<String> _weekdaysEnShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
}
