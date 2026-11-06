import 'package:family_hub/features/bazar/reports/data/report_pdf_builder.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates a non-empty PDF with the bundled Bangla font', () async {
    final font = await rootBundle.load('assets/fonts/HindSiliguri-Regular.ttf');
    final bytes = await ReportPdfBuilder.build(
      title: 'Family report',
      reportText: 'পরিবারের প্রতিবেদন\nমোট: ৳১২৩.৪৫',
      fontData: font,
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(8)), startsWith('%PDF-'));
  });
}
