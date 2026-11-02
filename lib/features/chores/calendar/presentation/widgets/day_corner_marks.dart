import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// The two small corner marks of a day cell (B.3):
///
/// * NEEDS COVER - a person-search icon in the overdue container pair, top
///   start;
/// * NEEDS ATTENTION - a speech bubble in the accent container pair, bottom
///   end.
///
/// Each is a shape (an icon in a ring), never colour alone, and the cell's own
/// label names it, so the marks themselves are excluded from semantics. The
/// pairs are the theme's own container/on pairs, contrast-tested.
class DayCornerMarks extends StatelessWidget {
  const DayCornerMarks({
    required this.needsCover,
    required this.needsAttention,
    super.key,
  });

  final bool needsCover;
  final bool needsAttention;

  /// Diameter of one mark.
  static const double size = 14;

  @override
  Widget build(BuildContext context) {
    if (!needsCover && !needsAttention) return const SizedBox.shrink();
    final t = context.tokens;
    return ExcludeSemantics(
      child: Stack(
        children: [
          if (needsCover)
            PositionedDirectional(
              top: 2,
              start: 2,
              child: _Mark(
                key: const Key('calendar_mark_needs_cover'),
                icon: Icons.person_search_rounded,
                foreground: t.statusOverdueOn,
                container: t.statusOverdueContainer,
              ),
            ),
          if (needsAttention)
            PositionedDirectional(
              bottom: 2,
              end: 2,
              child: _Mark(
                key: const Key('calendar_mark_needs_attention'),
                icon: Icons.mode_comment_rounded,
                foreground: t.accentStrong,
                container: t.accentSoft,
              ),
            ),
        ],
      ),
    );
  }
}

/// A mark on its own (used by the legend): the same drawing as in the cell.
class DayCornerMark extends StatelessWidget {
  const DayCornerMark({required this.cover, super.key});

  /// True for the needs-cover mark, false for needs-attention.
  final bool cover;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ExcludeSemantics(
      child: cover
          ? _Mark(
              icon: Icons.person_search_rounded,
              foreground: t.statusOverdueOn,
              container: t.statusOverdueContainer,
            )
          : _Mark(
              icon: Icons.mode_comment_rounded,
              foreground: t.accentStrong,
              container: t.accentSoft,
            ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({
    required this.icon,
    required this.foreground,
    required this.container,
    super.key,
  });

  final IconData icon;
  final Color foreground;
  final Color container;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: DayCornerMarks.size,
      height: DayCornerMarks.size,
      decoration: BoxDecoration(
        color: container,
        shape: BoxShape.circle,
        border: Border.all(color: foreground),
      ),
      child: Icon(icon, size: 9, color: foreground),
    );
  }
}
