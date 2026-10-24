import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppFormatters — dates', () {
    test('fullDate renders Bangla month name and digits', () {
      const f = AppFormatters(languageCode: 'bn', useBanglaDigits: true);
      // 14 October 2026 → ১৪ অক্টোবর ২০২৬
      expect(f.fullDate(DateTime(2026, 10, 14)), '১৪ অক্টোবর ২০২৬');
    });

    test('fullDate renders English month name and ASCII digits', () {
      const f = AppFormatters(languageCode: 'en', useBanglaDigits: false);
      expect(f.fullDate(DateTime(2026, 10, 14)), '14 October 2026');
    });

    test('fullDate keeps Bangla month but ASCII digits when digits off', () {
      const f = AppFormatters(languageCode: 'bn', useBanglaDigits: false);
      expect(f.fullDate(DateTime(2026, 1, 3)), '3 জানুয়ারি 2026');
    });

    test('monthName covers all twelve months in both languages', () {
      const bn = AppFormatters(languageCode: 'bn', useBanglaDigits: true);
      const en = AppFormatters(languageCode: 'en', useBanglaDigits: false);
      expect(bn.monthName(1), 'জানুয়ারি');
      expect(bn.monthName(12), 'ডিসেম্বর');
      expect(en.monthName(1), 'January');
      expect(en.monthName(12), 'December');
      for (var m = 1; m <= 12; m++) {
        expect(bn.monthName(m), isNotEmpty);
        expect(en.monthName(m), isNotEmpty);
      }
    });

    test('monthName rejects out-of-range months', () {
      const f = AppFormatters(languageCode: 'bn', useBanglaDigits: true);
      expect(() => f.monthName(0), throwsRangeError);
      expect(() => f.monthName(13), throwsRangeError);
    });
  });

  group('AppFormatters — weekdays', () {
    test('weekdayName maps DateTime.weekday correctly', () {
      const bn = AppFormatters(languageCode: 'bn', useBanglaDigits: true);
      const en = AppFormatters(languageCode: 'en', useBanglaDigits: false);
      // 2026-10-14 is a Wednesday (weekday 3).
      expect(DateTime(2026, 10, 14).weekday, 3);
      expect(bn.weekdayName(3), 'বুধবার');
      expect(en.weekdayName(3), 'Wednesday');
    });

    test('weekdayShort returns compact labels', () {
      const bn = AppFormatters(languageCode: 'bn', useBanglaDigits: true);
      const en = AppFormatters(languageCode: 'en', useBanglaDigits: false);
      expect(bn.weekdayShort(5), 'শুক্র');
      expect(en.weekdayShort(5), 'Fri');
    });

    test('weekday rejects out-of-range values', () {
      const f = AppFormatters(languageCode: 'en', useBanglaDigits: false);
      expect(() => f.weekdayName(0), throwsRangeError);
      expect(() => f.weekdayName(8), throwsRangeError);
    });
  });

  group('AppFormatters — numbers', () {
    test('Bangla grouping uses the lakh system (১,২৩,৪৫৬)', () {
      const f = AppFormatters(languageCode: 'bn', useBanglaDigits: true);
      expect(f.number(123456), '১,২৩,৪৫৬');
      expect(f.number(1234567), '১২,৩৪,৫৬৭');
    });

    test('English grouping uses international system (123,456)', () {
      const f = AppFormatters(languageCode: 'en', useBanglaDigits: false);
      expect(f.number(123456), '123,456');
      expect(f.number(1234567), '1,234,567');
    });

    test('small numbers are never grouped', () {
      const f = AppFormatters(languageCode: 'bn', useBanglaDigits: true);
      expect(f.number(0), '০');
      expect(f.number(999), '৯৯৯');
    });

    test('negatives keep the sign and the digit script', () {
      const bn = AppFormatters(languageCode: 'bn', useBanglaDigits: true);
      const en = AppFormatters(languageCode: 'en', useBanglaDigits: false);
      expect(bn.number(-1234), '-১,২৩৪');
      expect(en.number(-1234), '-1,234');
    });

    test('digit script follows the switch, not the language', () {
      const bnAscii = AppFormatters(languageCode: 'bn', useBanglaDigits: false);
      const enBangla = AppFormatters(languageCode: 'en', useBanglaDigits: true);
      expect(bnAscii.number(1234), '1,234');
      expect(enBangla.number(1234), '১,২৩৪');
    });
  });

  group('AppFormatters — money', () {
    test('Bangla money uses Bangla digits and taka symbol', () {
      const f = AppFormatters(languageCode: 'bn', useBanglaDigits: true);
      final text = f.money(const Money.paisa(1234567));
      expect(text, contains('৳'));
      expect(text, contains('১'));
      expect(text.contains('0'), isFalse, reason: 'no ASCII digits expected');
    });

    test('English money uses ASCII digits', () {
      const f = AppFormatters(languageCode: 'en', useBanglaDigits: false);
      final text = f.money(const Money.paisa(1234567));
      expect(text, contains('৳'));
      expect(text, contains('1'));
    });

    test('hideZeroFraction drops the .00 tail', () {
      const f = AppFormatters(languageCode: 'en', useBanglaDigits: false);
      expect(f.money(const Money.paisa(20000), hideZeroFraction: true), '৳200');
    });
  });

  group('AppFormatters — monthLabel', () {
    test('Bangla month and digits', () {
      const f = AppFormatters(languageCode: 'bn', useBanglaDigits: true);
      expect(f.monthLabel(MonthKey(2026, 10)), 'অক্টোবর ২০২৬');
    });

    test('English month and ASCII digits', () {
      const f = AppFormatters(languageCode: 'en', useBanglaDigits: false);
      expect(f.monthLabel(MonthKey(2026, 10)), 'October 2026');
    });

    test('Bangla month with ASCII digits when the switch is off', () {
      const f = AppFormatters(languageCode: 'bn', useBanglaDigits: false);
      expect(f.monthLabel(MonthKey(2027, 1)), 'জানুয়ারি 2027');
    });

    test('the year is never grouped', () {
      const f = AppFormatters(languageCode: 'en', useBanglaDigits: false);
      expect(f.monthLabel(MonthKey(2026, 12)), isNot(contains(',')));
    });
  });
}
