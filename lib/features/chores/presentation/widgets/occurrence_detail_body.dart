import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_item.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_event.dart';
import 'package:family_hub/features/chores/presentation/widgets/occurrence_header.dart';
import 'package:family_hub/features/chores/presentation/widgets/occurrence_timeline.dart';
import 'package:family_hub/features/chores/presentation/widgets/subtask_checklist.dart';
import 'package:family_hub/shared/widgets/mini_markdown_view.dart';
import 'package:family_hub/shared/widgets/responsive_layout.dart';
import 'package:flutter/material.dart';

/// The scrolling body of the chore detail screen (P3-15): header, steps,
/// instructions and history.
///
/// A plain widget with no providers, so the screen keeps the session and the
/// actions while this file stays a layout file (R0-4, 300-line rule).
class OccurrenceDetailBody extends StatelessWidget {
  const OccurrenceDetailBody({
    required this.item,
    required this.occurrence,
    required this.events,
    required this.formatters,
    required this.today,
    required this.busy,
    required this.onToggleParent,
    required this.onToggleSubtask,
    this.comments,
    this.banner,
    this.reminderWhyLine,
    super.key,
  });

  final ChoreItem item;
  final ChoreOccurrence occurrence;
  final List<OccurrenceEvent> events;
  final AppFormatters formatters;
  final DateKey today;
  final bool busy;
  final VoidCallback onToggleParent;
  final ValueChanged<String> onToggleSubtask;

  /// The comment thread (P3-25); built by the screen so this file stays a
  /// layout file with no providers.
  final Widget? comments;

  /// The pending swap request of this chore (P3-27), above everything else.
  final Widget? banner;
  final Widget? reminderWhyLine;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final details = <Widget>[
      ?banner,
      OccurrenceHeader(item: item, formatters: formatters, today: today),
      ?reminderWhyLine,
      const SizedBox(height: 20),
      SubtaskChecklist(
        item: item,
        occurrence: occurrence,
        formatters: formatters,
        busy: busy,
        onToggleParent: onToggleParent,
        onToggleSubtask: onToggleSubtask,
      ),
      if (occurrence.instructions.trim().isNotEmpty) ...[
        const SizedBox(height: 20),
        Text(
          context.l10n.occurrenceInstructionsTitle,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: t.textPrimary),
        ),
        const SizedBox(height: 8),
        MiniMarkdownView(markdown: occurrence.instructions),
      ],
    ];
    final discussion = <Widget>[
      if (comments != null) ...[const SizedBox(height: 20), comments!],
      const SizedBox(height: 20),
      OccurrenceTimeline(events: events, formatters: formatters),
    ];

    // P4-24: on a wide screen the chore itself stays on the left and the
    // thread (comments + history) gets its own scrolling pane on the right.
    if (context.layoutClass.showsTwoPanes) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
              children: details,
            ),
          ),
          Expanded(
            flex: 2,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
              children: discussion,
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [...details, ...discussion],
    );
  }
}
