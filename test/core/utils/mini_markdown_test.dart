import 'package:family_hub/core/utils/mini_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

/// P3-02: the subset parser. Every input is total: it never throws and never
/// loses a character, so a hostile or garbled `houseRules` string can only
/// render as plain text.
void main() {
  String plain(List<MdBlock> blocks) =>
      blocks.map((block) => block.plainText).join('|');

  group('blocks', () {
    test('an empty or blank source has no blocks', () {
      expect(MiniMarkdown.parse(''), isEmpty);
      expect(MiniMarkdown.parse('\n\n   \n\t\n'), isEmpty);
    });

    test('a plain line is one paragraph', () {
      final blocks = MiniMarkdown.parse('বাসন ধোয়া');
      expect(blocks, hasLength(1));
      expect(blocks.single, isA<MdParagraph>());
      expect(blocks.single.spans, const <MdText>[MdText('বাসন ধোয়া')]);
    });

    test('dash and bullet characters both make a bullet', () {
      final blocks = MiniMarkdown.parse('- wash dishes\n• sweep floor');
      expect(blocks, hasLength(2));
      expect(blocks[0], isA<MdBullet>());
      expect(blocks[0].plainText, 'wash dishes');
      expect(blocks[1], isA<MdBullet>());
      expect(blocks[1].plainText, 'sweep floor');
    });

    test('a numbered line keeps its number', () {
      final blocks = MiniMarkdown.parse('1. first\n12. twelfth');
      expect(blocks[0], isA<MdNumbered>());
      expect((blocks[0] as MdNumbered).n, 1);
      expect((blocks[1] as MdNumbered).n, 12);
      expect(blocks[1].plainText, 'twelfth');
    });

    test('a heading needs the hash and the space', () {
      final blocks = MiniMarkdown.parse('# ঘরের নিয়ম\n#nohash');
      expect(blocks[0], isA<MdHeading>());
      expect(blocks[0].plainText, 'ঘরের নিয়ম');
      expect(blocks[1], isA<MdParagraph>());
    });

    test('an unspaced dash or number is plain text', () {
      final blocks = MiniMarkdown.parse('-dash\n1.number');
      expect(blocks[0], isA<MdParagraph>());
      expect(blocks[1], isA<MdParagraph>());
    });

    test('blocks keep their order and blank lines separate them', () {
      final blocks = MiniMarkdown.parse('# Title\n\n- a\n- b\n\n1. c');
      expect(blocks.map((block) => block.runtimeType.toString()), [
        'MdHeading',
        'MdBullet',
        'MdBullet',
        'MdNumbered',
      ]);
    });
  });

  group('bold', () {
    test('a pair of markers makes its content bold', () {
      final block = MiniMarkdown.parse('wash **the pots** now').single;
      expect(block.spans, const <MdText>[
        MdText('wash '),
        MdText('the pots', bold: true),
        MdText(' now'),
      ]);
    });

    test('bold at the very start and end of a line', () {
      final block = MiniMarkdown.parse('**সবাই**').single;
      expect(block.spans, const <MdText>[MdText('সবাই', bold: true)]);
    });

    test('several pairs on one line', () {
      final block = MiniMarkdown.parse('**a** and **b**').single;
      expect(block.spans, const <MdText>[
        MdText('a', bold: true),
        MdText(' and '),
        MdText('b', bold: true),
      ]);
    });

    test('an unclosed marker stays literal text', () {
      final block = MiniMarkdown.parse('**never closed').single;
      expect(block.plainText, '**never closed');
      expect(block.spans.any((span) => span.bold), isFalse);
    });

    test('bold is not nested: the inner markers stay literal', () {
      final block = MiniMarkdown.parse('**a **b** c**').single;
      expect(block.plainText, 'a b c');
      // Four markers: the first and third runs are bold.
      expect(block.spans.where((span) => span.bold).map((s) => s.text), [
        'a ',
        ' c',
      ]);
    });

    test('a bullet can be bold', () {
      final block = MiniMarkdown.parse('- **জরুরি** কাজ').single;
      expect(block, isA<MdBullet>());
      expect(block.spans.first, const MdText('জরুরি', bold: true));
      expect(block.spans.last, const MdText(' কাজ'));
    });
  });

  group('robustness', () {
    test('HTML and links are plain text, never markup', () {
      final blocks = MiniMarkdown.parse('<b>x</b> [link](http://e.vil)');
      expect(blocks.single.plainText, '<b>x</b> [link](http://e.vil)');
    });

    test('no character is lost in a mixed document', () {
      final lines = List.generate(
        100,
        (i) => i.isEven ? '# Head $i' : '- item **$i** with বাংলা',
      );
      final blocks = MiniMarkdown.parse(lines.join('\n'));
      expect(blocks, hasLength(100));
      // Markers are the only characters the parser may remove.
      final expected = lines
          .map((line) => line.replaceAll('**', ''))
          .map(
            (line) => line
                .replaceFirst(RegExp(r'^# '), '')
                .replaceFirst(RegExp(r'^- '), ''),
          )
          .join('|');
      expect(plain(blocks), expected);
    });

    test('Windows line endings are handled', () {
      final blocks = MiniMarkdown.parse('- a\r\n- b');
      expect(blocks, hasLength(2));
      expect(blocks[0].plainText, 'a');
      expect(blocks[1].plainText, 'b');
    });

    test('a 4000-character document parses in under 5 ms', () {
      final source = List.generate(
        40,
        (i) => '**সকাল** ${'কাজ ' * 40}$i',
      ).join('\n');
      expect(source.length, greaterThanOrEqualTo(4000));
      var blocks = const <MdBlock>[];
      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < 20; i++) {
        blocks = MiniMarkdown.parse(source);
      }
      stopwatch.stop();
      expect(blocks, hasLength(40));
      expect(
        stopwatch.elapsedMilliseconds / 20,
        lessThan(5),
        reason: '20 parses took ${stopwatch.elapsedMilliseconds} ms',
      );
    });
  });
}
