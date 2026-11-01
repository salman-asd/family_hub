import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/templates/domain/template_parts.dart';
import 'package:family_hub/shared/widgets/mini_markdown_view.dart';
import 'package:flutter/material.dart';

/// Edits a chore's instructions as mini-markdown, with a toolbar (bold, bullet
/// list, numbered list) and a live preview toggle (P3-16).
///
/// The syntax is the one `MiniMarkdown` parses: `**bold**`, `- bullet` and
/// `1. numbered` lines. The toolbar only edits text around the selection; the
/// parser and [MiniMarkdownView] decide what it looks like, so the preview is
/// exactly what the occurrence screen shows.
class InstructionsEditor extends StatefulWidget {
  const InstructionsEditor({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  State<InstructionsEditor> createState() => _InstructionsEditorState();
}

class _InstructionsEditorState extends State<InstructionsEditor> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  bool _preview = false;

  @override
  void didUpdateWidget(covariant InstructionsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply(TextEditingValue value) {
    _controller.value = value;
    widget.onChanged(value.text);
  }

  TextSelection get _selection {
    final sel = _controller.selection;
    if (sel.isValid) return sel;
    return TextSelection.collapsed(offset: _controller.text.length);
  }

  void _bold() {
    final text = _controller.text;
    final sel = _selection;
    final selected = sel.textInside(text);
    final next = '${sel.textBefore(text)}**$selected**${sel.textAfter(text)}';
    final caret = selected.isEmpty
        ? sel.start + 2
        : sel.start + selected.length + 4;
    _apply(
      TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: caret),
      ),
    );
  }

  /// Prefixes every line touched by the selection; [prefix] gets the 0-based
  /// line number so a numbered list counts 1, 2, 3.
  void _prefixLines(String Function(int) prefix) {
    final text = _controller.text;
    final sel = _selection;
    final start = sel.start == 0
        ? 0
        : text.lastIndexOf('\n', sel.start - 1) + 1;
    final newline = text.indexOf('\n', sel.end);
    final end = newline < 0 ? text.length : newline;
    final lines = text.substring(start, end).split('\n');
    final changed = <String>[
      for (var i = 0; i < lines.length; i++) '${prefix(i)}${lines[i]}',
    ].join('\n');
    final next = text.replaceRange(start, end, changed);
    _apply(
      TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: start + changed.length),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              key: const ValueKey<String>('instr_bold'),
              tooltip: l10n.choreInstructionsBold,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: widget.enabled && !_preview ? _bold : null,
              icon: const Icon(Icons.format_bold_rounded),
            ),
            IconButton(
              key: const ValueKey<String>('instr_bullet'),
              tooltip: l10n.choreInstructionsBullet,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: widget.enabled && !_preview
                  ? () => _prefixLines((_) => '- ')
                  : null,
              icon: const Icon(Icons.format_list_bulleted_rounded),
            ),
            IconButton(
              key: const ValueKey<String>('instr_numbered'),
              tooltip: l10n.choreInstructionsNumbered,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: widget.enabled && !_preview
                  ? () => _prefixLines((i) => '${i + 1}. ')
                  : null,
              icon: const Icon(Icons.format_list_numbered_rounded),
            ),
            FilterChip(
              key: const ValueKey<String>('instr_preview'),
              label: Text(l10n.choresSettingsHouseRulesPreview),
              avatar: const Icon(Icons.visibility_outlined, size: 18),
              selected: _preview,
              showCheckmark: true,
              onSelected: (v) => setState(() => _preview = v),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_preview)
          MiniMarkdownView(
            markdown: widget.value,
            emptyText: l10n.choreInstructionsEmpty,
          )
        else
          TextField(
            key: const ValueKey<String>('instructions_field'),
            controller: _controller,
            enabled: widget.enabled,
            maxLength: TemplateLimits.maxInstructionsLength,
            maxLines: 12,
            minLines: 5,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: l10n.choreInstructionsHint,
            ),
            onChanged: widget.onChanged,
          ),
      ],
    );
  }
}
