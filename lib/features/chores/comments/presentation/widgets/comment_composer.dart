import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/comments/domain/occurrence_comment.dart';
import 'package:flutter/material.dart';

/// The comment box under a chore (P3-25): a text field, a "flag" switch and
/// Send.
///
/// It owns only the text; [onSubmit] runs the use case and answers whether it
/// worked. The field is cleared on success and KEPT on failure, so a message is
/// never lost. A flag needs a reason, which is the text itself.
class CommentComposer extends StatefulWidget {
  const CommentComposer({required this.onSubmit, super.key});

  final Future<bool> Function(String text, bool flagged) onSubmit;

  @override
  State<CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<CommentComposer> {
  final TextEditingController _controller = TextEditingController();
  bool _flagged = false;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _valid => _controller.text.trim().isNotEmpty;

  Future<void> _send() async {
    if (_sending || !_valid) return;
    setState(() => _sending = true);
    final done = await widget.onSubmit(_controller.text, _flagged);
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (done) {
        _controller.clear();
        _flagged = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          minLines: 1,
          maxLines: 5,
          maxLength: CommentLimits.maxText,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: l10n.commentsHint),
          onChanged: (_) => setState(() {}),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          secondary: Icon(
            _flagged ? Icons.flag_rounded : Icons.flag_outlined,
            color: _flagged ? t.statusOverdue : t.textSecondary,
          ),
          title: Text(l10n.commentsFlagLabel),
          value: _flagged,
          onChanged: _sending ? null : (v) => setState(() => _flagged = v),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              backgroundColor: t.accent,
              foregroundColor: t.textOnAccent,
            ),
            onPressed: _valid && !_sending ? _send : null,
            icon: _sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(l10n.commentsSend),
          ),
        ),
      ],
    );
  }
}
