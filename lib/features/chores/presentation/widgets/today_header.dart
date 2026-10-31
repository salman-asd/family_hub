import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/occurrences/presentation/today_providers.dart';
import 'package:family_hub/features/chores/settings/domain/chore_catalog_entries.dart';
import 'package:family_hub/shared/widgets/choice_wrap.dart';
import 'package:family_hub/shared/widgets/progress_ring.dart';
import 'package:flutter/material.dart';

/// The top of the Today screen: a progress ring, "3 of 7 done" and the
/// Mine / Whole family toggle (P3-15, U-05).
///
/// It sits in the body, not in `AppBar.bottom`, so it has no fixed height and
/// wraps at text scale 2.0 in Bangla instead of overflowing.
class TodayHeader extends StatelessWidget {
  const TodayHeader({
    required this.progress,
    required this.scope,
    required this.onScope,
    required this.formatters,
    super.key,
  });

  final TodayProgress progress;
  final CalendarScopeKind scope;
  final ValueChanged<CalendarScopeKind> onScope;
  final AppFormatters formatters;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final text = l10n.todayProgress(
      formatters.number(progress.done),
      formatters.number(progress.total),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ProgressRing(
            value: progress.fraction,
            size: 56,
            semanticLabel: text,
            center: Text(
              formatters.number(progress.done),
              style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Text(text, style: TextStyle(color: t.textSecondary)),
                ),
                const SizedBox(height: 4),
                ChoiceWrap<CalendarScopeKind>(
                  selected: scope,
                  onChanged: onScope,
                  options: <ChoiceOption<CalendarScopeKind>>[
                    ChoiceOption(CalendarScopeKind.mine, l10n.todayScopeMine),
                    ChoiceOption(CalendarScopeKind.all, l10n.todayScopeFamily),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
