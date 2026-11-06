import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

abstract final class ReportPdfBuilder {
  static Future<Uint8List> build({
    required String title,
    required String reportText,
    required ByteData fontData,
  }) async {
    final document = pw.Document();
    final font = pw.Font.ttf(fontData);
    document.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font),
        build: (context) => <pw.Widget>[
          pw.Header(level: 0, child: pw.Text(title)),
          for (final line in reportText.split('\n'))
            pw.Text(line.isEmpty ? ' ' : line),
        ],
      ),
    );
    return document.save();
  }
}
