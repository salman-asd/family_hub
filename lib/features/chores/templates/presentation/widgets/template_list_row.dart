import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/presentation/chore_icons.dart';
import 'package:family_hub/features/chores/templates/domain/chore_template.dart';
import 'package:family_hub/features/chores/templates/domain/recurrence/recurrence_describe.dart';
import 'package:family_hub/features/chores/templates/presentation/template_labels.dart';
import 'package:family_hub/features/chores/templates/presentation/widgets/next_dates_preview.dart';
import 'package:family_hub/features/chores/templates/presentation/widgets/recurrence_summary_text.dart';
import 'package:flutter/material.dart';

/// One row of the template list (P3-16): name, the repeat rule as a sentence,
/// who it is assigned to, how many times a day, and the next date.
///
/// A paused, archived or unreadable template says so with an icon AND a word
/// (never colour alone).
class TemplateListRow extends StatelessWidget {
  const TemplateListRow({
    required this.template,
    required this.today,
    required this.formatters,
    required this.invalidSchedule,
    required this.onTap,
    super.key,
  });

  final ChoreTemplate template;
  final DateKey today;
  final AppFormatters formatters;
  final bool invalidSchedule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final draft = template.draft;

    final next = template.isGenerating && !invalidSchedule
        ? NextDatesPreview.dates(
            recurrence: draft.recurrence,
            startDate: draft.startDate,
            endDate: draft.endDate,
            today: today,
            count: 1,
          )
        : const <DateKey>[];
    final nextText = next.isEmpty
        ? null
        : l10n.choreListNext(
            formatters.fullDate(
              DateTime(next.first.year, next.first.month, next.first.day),
            ),
          );

    final (IconData, String)? badge = invalidSchedule
        ? (Icons.error_outline_rounded, l10n.choreListInvalidSchedule)
        : template.isArchived
        ? (Icons.archive_outlined, l10n.choreStatusArchived)
        : !template.active
        ? (Icons.pause_circle_outline_rounded, l10n.choreStatusPaused)
        : null;

    final sentence = RecurrenceSummaryText.text(
      l10n,
      formatters,
      RecurrenceSummary.of(draft.recurrence),
    );
    final name = localizedName(context, draft.nameBn, draft.nameEn);
    final details = <String>[
      sentence,
      strategyLabel(l10n, draft.assignee.strategy),
      l10n.choreSlotCount(formatters.number(draft.slots.length)),
      ?nextText,
    ].join(' · ');

    return Semantics(
      button: true,
      label: '$name. $details${badge == null ? '' : '. ${badge.$2}'}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(t.radiusMd),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(t.radiusMd),
            border: Border.all(color: t.outline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(choreIcon(draft.iconKey), color: t.accentStrong),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: text.titleSmall?.copyWith(color: t.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details,
                      style: text.bodySmall?.copyWith(color: t.textSecondary),
                    ),
                    if (badge != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badge.$1, size: 16, color: t.textSecondary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              badge.$2,
                              style: text.labelMedium?.copyWith(
                                color: t.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
