import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/reports/domain/report_text_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final data = ReportTextData(
    period: ReportTextPeriod.monthly,
    range: DateKeyRange(DateKey(2026, 4, 1), DateKey(2026, 4, 30)),
    bazarTotal: const Money.paisa(123450),
    categories: const <ReportTextCategory>[
      ReportTextCategory(name: 'সবজি', total: Money.paisa(123450)),
    ],
    choresCompleted: 8,
    choresRemaining: 2,
    choresAwaitingVerification: 1,
    budget: const Money.paisa(200000),
    spent: const Money.paisa(123450),
    fundBalance: const Money.paisa(765432),
  );

  test('builds a complete Bangla monthly summary with Bangla digits', () {
    final text = ReportTextBuilder.build(data, languageCode: 'bn');

    expect(text, contains('মাসিক পরিবারের প্রতিবেদন'));
    expect(text, contains('সময়কাল: ২০২৬-০৪-০১ – ২০২৬-০৪-৩০'));
    expect(text, contains('বাজারের মোট: ৳১,২৩৪.৫০'));
    expect(text, contains('সবজি: ৳১,২৩৪.৫০'));
    expect(text, contains('সম্পন্ন: ৮'));
    expect(text, contains('বাকি: ২'));
    expect(text, contains('যাচাইয়ের অপেক্ষায়: ১'));
    expect(text, contains('তহবিলের স্থিতি: ৳৭,৬৫৪.৩২'));
  });

  test('builds a complete English monthly summary with English digits', () {
    final text = ReportTextBuilder.build(data, languageCode: 'en');

    expect(text, contains('Monthly family report'));
    expect(text, contains('Period: 2026-04-01 – 2026-04-30'));
    expect(text, contains('Bazar total: ৳1,234.50'));
    expect(text, contains('Completed: 8'));
    expect(text, contains('Remaining: 2'));
    expect(text, contains('Awaiting verification: 1'));
    expect(text, contains('Fund balance: ৳7,654.32'));
  });
}
