/// One run of text. [bold] is true for text inside `**…**`.
final class MdText {
  const MdText(this.text, {this.bold = false});

  final String text;
  final bool bold;

  @override
  bool operator ==(Object other) =>
      other is MdText && other.text == text && other.bold == bold;

  @override
  int get hashCode => Object.hash(text, bold);

  @override
  String toString() => bold ? 'MdText(bold: $text)' : 'MdText($text)';
}

/// Base type of every block [MiniMarkdown.parse] returns.
sealed class MdBlock {
  const MdBlock(this.spans);

  /// The inline runs of the block, in order. Never empty; an empty line is
  /// not a block at all.
  final List<MdText> spans;

  /// The block as plain text (bold markers removed) — for search, copy and
  /// screen-reader labels.
  String get plainText => spans.map((span) => span.text).join();
}

/// A normal line of text.
final class MdParagraph extends MdBlock {
  const MdParagraph(super.spans);
}

/// A line that started with `- ` or `• `.
final class MdBullet extends MdBlock {
  const MdBullet(super.spans);
}

/// A line that started with `1. ` — [n] is the number that was written.
final class MdNumbered extends MdBlock {
  const MdNumbered(this.n, super.spans);

  final int n;
}

/// A line that started with `# `.
final class MdHeading extends MdBlock {
  const MdHeading(super.spans);
}

/// A deliberately tiny, total markdown subset for `houseRules` and chore
/// instructions (D-P3-4, Appendix D): no HTML, no links, no images, so no
/// injection surface and no dependency.
///
/// Supported syntax only:
/// * `**bold**` inside any line (an unclosed `**` stays literal text)
/// * lines starting `- ` or `• ` become [MdBullet]
/// * lines starting `1. `, `2. ` … become [MdNumbered]
/// * lines starting `# ` become [MdHeading]
/// * anything else is a [MdParagraph]
///
/// Parsing is pure and linear in the input length; it never throws.
abstract final class MiniMarkdown {
  /// Parses [source] into blocks. Empty and whitespace-only lines are skipped.
  static List<MdBlock> parse(String source) {
    if (source.isEmpty) {
      return const <MdBlock>[];
    }
    final blocks = <MdBlock>[];
    for (final raw in source.split('\n')) {
      final line = raw.endsWith('\r') ? raw.substring(0, raw.length - 1) : raw;
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      if (trimmed.startsWith('# ')) {
        _add(blocks, trimmed.substring(2), MdHeading.new);
      } else if (trimmed.startsWith('- ')) {
        _add(blocks, trimmed.substring(2), MdBullet.new);
      } else if (trimmed.startsWith('• ')) {
        _add(blocks, trimmed.substring(2), MdBullet.new);
      } else {
        final numbered = _numbered.firstMatch(trimmed);
        if (numbered == null) {
          _add(blocks, trimmed, MdParagraph.new);
        } else {
          final n = int.parse(numbered.group(1)!);
          final rest = trimmed.substring(numbered.end).trimLeft();
          blocks.add(MdNumbered(n, _spans(rest)));
        }
      }
    }
    return List<MdBlock>.unmodifiable(blocks);
  }

  /// `1. `, `12. ` … at the start of an already trimmed line.
  static final RegExp _numbered = RegExp(r'^(\d{1,3})\.\s');

  static void _add(
    List<MdBlock> blocks,
    String text,
    MdBlock Function(List<MdText>) build,
  ) {
    final spans = _spans(text.trim());
    if (spans.isNotEmpty) {
      blocks.add(build(spans));
    }
  }

  /// Splits one line on `**` in a single left-to-right pass. A pair makes its
  /// content bold; an unclosed opening marker is kept as literal text (never
  /// throws, never drops characters: the concatenated spans always equal
  /// [line]).
  static List<MdText> _spans(String line) {
    var marker = line.indexOf('**');
    if (marker < 0) {
      return List<MdText>.unmodifiable(<MdText>[MdText(line)]);
    }
    final spans = <MdText>[];
    var cursor = 0;
    var open = -1;
    while (cursor < line.length) {
      if (open < 0) {
        if (marker < 0) {
          spans.add(MdText(line.substring(cursor)));
          break;
        }
        if (marker > cursor) {
          spans.add(MdText(line.substring(cursor, marker)));
        }
        open = marker;
        cursor = marker + 2;
      } else {
        if (marker < 0) {
          // Unclosed: the opener and everything after it stay literal.
          spans.add(MdText(line.substring(open)));
          break;
        }
        spans.add(MdText(line.substring(cursor, marker), bold: true));
        open = -1;
        cursor = marker + 2;
      }
      marker = line.indexOf('**', cursor);
    }
    if (spans.isEmpty) {
      return List<MdText>.unmodifiable(<MdText>[MdText(line)]);
    }
    return List<MdText>.unmodifiable(spans);
  }
}
