import 'package:family_hub/core/utils/mini_markdown.dart';
import 'package:flutter/material.dart';

/// Renders the output of [MiniMarkdown.parse] with the theme's own text styles
/// (P3-04).
///
/// There is no HTML and no markdown package: the parser only produces
/// paragraphs, bullets, numbered lines, headings and bold runs, so the renderer
/// is a small `Column` of `Text.rich` and nothing can be injected.
///
/// [selectable] turns the text into `SelectableText`-style ranges (chore
/// instructions are worth copying); it defaults to off because a selectable
/// block inside a list row swallows horizontal drags.
class MiniMarkdownView extends StatelessWidget {
  const MiniMarkdownView({
    required this.markdown,
    this.selectable = false,
    this.emptyText,
    super.key,
  });

  /// Raw markdown source (for example `houseRules` or a template's
  /// `instructions`). Parsed here, so callers pass the stored string.
  final String markdown;

  final bool selectable;

  /// Shown when the source is empty or only whitespace.
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    final blocks = MiniMarkdown.parse(markdown);
    if (blocks.isEmpty) {
      final empty = emptyText;
      if (empty == null) return const SizedBox.shrink();
      return Text(
        empty,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: Theme.of(context).hintColor),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < blocks.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : _gap(blocks[i])),
            child: _BlockView(block: blocks[i], selectable: selectable),
          ),
      ],
    );
  }

  /// Headings breathe more above them than ordinary lines do.
  static double _gap(MdBlock block) => block is MdHeading ? 12 : 4;
}

class _BlockView extends StatelessWidget {
  const _BlockView({required this.block, required this.selectable});

  final MdBlock block;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final style = switch (block) {
      MdHeading() => theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      MdParagraph() => theme.textTheme.bodyMedium,
      MdBullet() || MdNumbered() => theme.textTheme.bodyMedium,
    };
    final span = TextSpan(children: _spans(block, style, theme));
    final text = selectable
        ? SelectableText.rich(span, style: style)
        : Text.rich(span, style: style);

    return switch (block) {
      MdHeading() || MdParagraph() => text,
      MdBullet() => _Marked(marker: _bullet, child: text),
      MdNumbered(:final n) => _Marked(marker: '$n.', child: text),
    };
  }

  /// A real bullet character; kept as a code unit so the file stays ASCII.
  static final String _bullet = String.fromCharCode(0x2022);

  static List<TextSpan> _spans(
    MdBlock block,
    TextStyle? style,
    ThemeData theme,
  ) => [
    for (final run in block.spans)
      TextSpan(
        text: run.text,
        style: run.bold
            ? (style ?? const TextStyle()).copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              )
            : style,
      ),
  ];
}

/// A bullet or number in a fixed gutter, wrapping like a list item.
class _Marked extends StatelessWidget {
  const _Marked({required this.marker, required this.child});

  final String marker;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          child: Text(
            marker,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
